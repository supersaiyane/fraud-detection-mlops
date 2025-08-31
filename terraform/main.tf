terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region
}

# -------------------------
# S3 Bucket for training data & logs
# -------------------------
resource "aws_s3_bucket" "fraud_data" {
  bucket = "${var.project}-fraud-data"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.fraud_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------------
# DynamoDB suspicious txn table
# -------------------------
resource "aws_dynamodb_table" "fraud_txns" {
  name           = "${var.project}-suspicious-txns"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "txn_id"

  attribute {
    name = "txn_id"
    type = "S"
  }
}

# -------------------------
# IAM Roles
# -------------------------

# SageMaker execution role
resource "aws_iam_role" "sagemaker_role" {
  name = "${var.project}-sagemaker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_attach" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Lambda execution role
resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sagemaker" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# -------------------------
# Lambda Function
# -------------------------
resource "aws_lambda_function" "fraud_api" {
  function_name = "${var.project}-fraud-api"
  role          = aws_iam_role.lambda_role.arn
  handler       = "fraud_lambda.lambda_handler"
  runtime       = "python3.10"

  filename         = "${path.module}/../lambda/fraud_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/fraud_lambda.zip")

  environment {
    variables = {
      SAGEMAKER_ENDPOINT = var.sagemaker_endpoint_name
    }
  }
}

# -------------------------
# API Gateway
# -------------------------
resource "aws_apigatewayv2_api" "fraud_api" {
  name          = "${var.project}-fraud-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "fraud_lambda_integration" {
  api_id           = aws_apigatewayv2_api.fraud_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.fraud_api.invoke_arn
}

resource "aws_apigatewayv2_route" "fraud_route" {
  api_id    = aws_apigatewayv2_api.fraud_api.id
  route_key = "POST /fraud-check"
  target    = "integrations/${aws_apigatewayv2_integration.fraud_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "fraud_stage" {
  api_id      = aws_apigatewayv2_api.fraud_api.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fraud_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.fraud_api.execution_arn}/*/*"
}

# -------------------------
# CloudWatch Log Groups
# -------------------------
resource "aws_cloudwatch_log_group" "fraud_api_logs" {
  name              = "/aws/lambda/${aws_lambda_function.fraud_api.function_name}"
  retention_in_days = 14
}

