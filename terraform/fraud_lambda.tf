# IAM Role for Fraud Lambda
resource "aws_iam_role" "fraud_lambda_role" {
  name = "${var.project}-fraud-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach managed policies for Lambda execution
resource "aws_iam_role_policy_attachment" "fraud_lambda_basic_execution" {
  role       = aws_iam_role.fraud_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom inline policy: SageMaker + DynamoDB access
resource "aws_iam_role_policy" "fraud_lambda_policy" {
  name = "${var.project}-fraud-lambda-policy"
  role = aws_iam_role.fraud_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sagemaker:InvokeEndpoint"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.fraud_txns.arn
      }
    ]
  })
}

# Fraud Lambda Function
resource "aws_lambda_function" "fraud_lambda" {
  function_name = "${var.project}-fraud-lambda"
  role          = aws_iam_role.fraud_lambda_role.arn
  handler       = "fraud_lambda.lambda_handler"
  runtime       = "python3.9"

  filename         = "${path.module}/../lambda/fraud_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/fraud_lambda.zip")

  memory_size = 512
  timeout     = 30

  environment {
    variables = {
      ENDPOINT_NAME  = var.sagemaker_endpoint_name
      DYNAMODB_TABLE = aws_dynamodb_table.fraud_txns.name
      REDIS_HOST     = aws_elasticache_cluster.fraud_cache.cache_nodes[0].address
    }
  }

  tags = {
    Project = var.project
    Purpose = "FraudDetectionAPI"
  }
}

# Allow API Gateway to invoke Fraud Lambda
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fraud_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fraud_api.execution_arn}/*/*"
}

# CloudWatch Log Group (30-day retention)
resource "aws_cloudwatch_log_group" "fraud_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.fraud_lambda.function_name}"
  retention_in_days = 30
}
