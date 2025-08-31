# -------------------------------------------------------
# CloudWatch Log Group for Endpoint Monitoring
# -------------------------------------------------------
resource "aws_cloudwatch_log_group" "sagemaker_monitor_logs" {
  name              = "/aws/sagemaker/endpoint/${var.sagemaker_endpoint_name}"
  retention_in_days = 14
}

# -------------------------------------------------------
# CloudWatch Alarms (Guardrails)
# -------------------------------------------------------

# Latency Alarm
resource "aws_cloudwatch_metric_alarm" "latency_alarm" {
  alarm_name          = "${var.project}-latency-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ModelLatency"
  namespace           = "AWS/SageMaker"
  period              = 60
  statistic           = "Average"
  threshold           = 200 # ms threshold for 95th percentile latency
  dimensions = {
    EndpointName = var.sagemaker_endpoint_name
  }
  alarm_description = "Alert if latency > 200ms"
  alarm_actions     = [aws_sns_topic.guardrails.arn]
}

# Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "${var.project}-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXErrors"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  dimensions = {
    ApiName = "${var.project}-fraud-api"
  }
  alarm_description = "Alert if API returns 5xx > 5/min"
  alarm_actions     = [aws_sns_topic.guardrails.arn]
}

# -------------------------------------------------------
# SNS Topic for Guardrail Alerts
# -------------------------------------------------------
resource "aws_sns_topic" "guardrails" {
  name = "${var.project}-guardrails-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.guardrails.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# -------------------------------------------------------
# SageMaker Model Monitor (Data Quality Drift)
# -------------------------------------------------------
resource "aws_sagemaker_model_quality_job_definition" "fraud_quality_monitor" {
  job_definition_name = "${var.project}-quality-monitor"
  role_arn            = aws_iam_role.sagemaker_pipeline_role.arn

  monitoring_app_specification {
    image_uri = "156387875391.dkr.ecr.us-east-1.amazonaws.com/sagemaker-model-monitor-analyzer" # region-specific
  }

  monitoring_input {
    endpoint_input {
      endpoint_name       = var.sagemaker_endpoint_name
      local_path          = "/opt/ml/processing/input"
      s3_data_distribution_type = "FullyReplicated"
    }
  }

  monitoring_output {
    s3_output {
      local_path = "/opt/ml/processing/output"
      s3_uri     = "s3://${aws_s3_bucket.fraud_data.bucket}/monitoring-output/"
      s3_upload_mode = "EndOfJob"
    }
  }

  stopping_condition {
    max_runtime_in_seconds = 1800
  }
}
