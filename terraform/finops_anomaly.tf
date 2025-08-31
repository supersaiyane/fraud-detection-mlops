resource "aws_ce_anomaly_monitor" "sagemaker_cost_monitor" {
  name              = "${var.project}-sagemaker-cost-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "sagemaker_cost_alerts" {
  name            = "${var.project}-sagemaker-cost-alerts"
  frequency       = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.sagemaker_cost_monitor.arn]

  subscribers {
    type    = "EMAIL"
    address = "finops-team@example.com"
  }
}
