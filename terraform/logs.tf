resource "aws_cloudwatch_log_group" "rollback_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.rollback_lambda.function_name}"
  retention_in_days = 30

  tags = {
    Project = var.project
    Purpose = "RollbackLambdaLogs"
  }
}
