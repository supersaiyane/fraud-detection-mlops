resource "aws_sns_topic" "rollback_alerts" {
  name = "${var.project}-rollback-alerts"
}

resource "aws_sns_topic_subscription" "rollback_lambda_sub" {
  topic_arn = aws_sns_topic.rollback_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.rollback_lambda.arn
}

# Allow SNS to invoke rollback Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rollback_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.rollback_alerts.arn
}

# Example SLO Alarm: P95 Latency > 200ms
resource "aws_cloudwatch_metric_alarm" "latency_alarm" {
  alarm_name          = "${var.project}-p95-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 200
  metric_name         = "ModelLatency"
  namespace           = "AWS/SageMaker"
  statistic           = "p95"
  period              = 60

  dimensions = {
    EndpointName = var.sagemaker_endpoint_name
  }

  alarm_actions = [aws_sns_topic.rollback_alerts.arn]
}
