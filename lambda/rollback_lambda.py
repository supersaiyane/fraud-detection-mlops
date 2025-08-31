import boto3
import os
import json
import urllib.request
import uuid
from datetime import datetime

sm = boto3.client("sagemaker")
dynamodb = boto3.client("dynamodb")

def post_webhook(url, message):
    if not url:
        return
    data = json.dumps({"text": message}).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    urllib.request.urlopen(req)

def lambda_handler(event, context):
    endpoint_name = os.environ["ENDPOINT_NAME"]
    slack_webhook = os.environ.get("SLACK_WEBHOOK", "")
    teams_webhook = os.environ.get("TEAMS_WEBHOOK", "")
    table_name = os.environ["DYNAMODB_TABLE"]

    print("Received SNS event:", json.dumps(event))

    rollback_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat()

    # Create new endpoint config with Prod=100%, Canary=0%
    new_config_name = f"{endpoint_name}-rollback-{rollback_id[:8]}"

    sm.create_endpoint_config(
        EndpointConfigName=new_config_name,
        ProductionVariants=[
            {
                "VariantName": "ProdVariant",
                "ModelName": f"{endpoint_name}-model",
                "InitialInstanceCount": 1,
                "InstanceType": "ml.m5.large",
                "InitialVariantWeight": 1.0
            },
            {
                "VariantName": "CanaryVariant",
                "ModelName": f"{endpoint_name}-model",
                "InitialInstanceCount": 1,
                "InstanceType": "ml.m5.large",
                "InitialVariantWeight": 0.0
            }
        ]
    )

    sm.update_endpoint(
        EndpointName=endpoint_name,
        EndpointConfigName=new_config_name
    )

    message = f"🚨 Rollback triggered for {endpoint_name}\nRollback ID: {rollback_id}\nTime: {timestamp}\nCanary disabled, Prod 100%."

    # Send Slack + Teams notifications
    post_webhook(slack_webhook, message)
    post_webhook(teams_webhook, message)

    # Log rollback in DynamoDB
    dynamodb.put_item(
        TableName=table_name,
        Item={
            "rollback_id": {"S": rollback_id},
            "endpoint": {"S": endpoint_name},
            "timestamp": {"S": timestamp},
            "status": {"S": "rolled_back"}
        }
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"message": f"Rollback completed for {endpoint_name}", "rollback_id": rollback_id})
    }
