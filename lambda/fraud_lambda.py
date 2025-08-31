import boto3
import json
import redis
import os

# DynamoDB
dynamodb = boto3.resource("dynamodb")
fraud_table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

# Redis ElastiCache (hostname must be passed via env var)
redis_host = os.environ.get("REDIS_HOST", None)
redis_client = redis.StrictRedis(host=redis_host, port=6379, decode_responses=True) if redis_host else None

def lambda_handler(event, context):
    txn = json.loads(event["body"])

    txn_id = txn.get("txn_id")
    amount = txn.get("amount")

    # Check cache first
    if redis_client:
        cached_score = redis_client.get(txn_id)
        if cached_score:
            return {
                "statusCode": 200,
                "body": json.dumps({"txn_id": txn_id, "fraud_score": float(cached_score), "source": "cache"})
            }

    # Call SageMaker endpoint
    sm_client = boto3.client("sagemaker-runtime")
    response = sm_client.invoke_endpoint(
        EndpointName=os.environ["ENDPOINT_NAME"],
        ContentType="application/json",
        Body=json.dumps(txn)
    )
    fraud_score = float(json.loads(response["Body"].read().decode("utf-8"))["score"])

    # Cache the score for future
    if redis_client:
        redis_client.setex(txn_id, 300, fraud_score)  # cache for 5 mins

    # Store suspicious txn
    if fraud_score > 0.8:
        fraud_table.put_item(Item={
            "txn_id": txn_id,
            "amount": amount,
            "fraud_score": fraud_score,
            "status": "SUSPICIOUS"
        })

    return {
        "statusCode": 200,
        "body": json.dumps({"txn_id": txn_id, "fraud_score": fraud_score})
    }
