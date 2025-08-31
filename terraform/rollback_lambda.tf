# -------------------------------------------------------
# IAM Role for Rollback Lambda
# -------------------------------------------------------
resource "aws_iam_role" "rollback_lambda_role" {
  name = "${var.project}-rollback-lambda-role"

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

resource "aws_iam_role_policy_attachment" "rollback_lambda_logs" {
  role       = aws_iam_role.rollback_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "rollback_lambda_sagemaker" {
  role       = aws_iam_role.rollback_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# -------------------------------------------------------
# Rollback Lambda Function
# -------------------------------------------------------
resource "aws_lambda_function" "rollback_lambda" {
  function_name = "${var.project}-rollback-lambda"
  role          = aws_iam_role.rollback_lambda_role.arn
  handler       = "rollback_lambda.lambda_handler"
  runtime       = "python3.10"

  filename         = "${path.module}/../lambda/rollback_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/rollback_lambda.zip")

  environment {
    variables = {
      ENDPOINT_NAME = var.sagemaker_endpoint_name
    }
  }
}

# -------------------------------------------------------
# Subscribe Rollback Lambda to SNS Guardrails
# -------------------------------------------------------
resource "aws_sns_topic_subscription" "rollback_sub" {
  topic_arn = aws_sns_topic.guardrails.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.rollback_lambda.arn
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rollback_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.guardrails.arn
}

# DynamoDB table for rollback logs
resource "aws_dynamodb_table" "rollback_logs" {
  name         = "${var.project}-rollback-logs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "rollback_id"

  attribute {
    name = "rollback_id"
    type = "S"
  }
}

# Rollback Lambda Function
resource "aws_lambda_function" "rollback_lambda" {
  function_name = "${var.project}-rollback-lambda"
  role          = aws_iam_role.rollback_lambda_role.arn
  handler       = "rollback_lambda.lambda_handler"
  runtime       = "python3.10"

  filename         = "${path.module}/../lambda/rollback_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/rollback_lambda.zip")

environment {
  variables = {
    ENDPOINT_NAME  = var.sagemaker_endpoint_name
    SLACK_WEBHOOK  = var.slack_webhook_url
    TEAMS_WEBHOOK  = var.teams_webhook_url
    DYNAMODB_TABLE = aws_dynamodb_table.rollback_logs.name
  }
}
}