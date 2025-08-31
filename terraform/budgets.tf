resource "aws_budgets_budget" "gpu_budget" {
  name              = "${var.project}-gpu-budget"
  budget_type       = "COST"
  limit_amount      = "500"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  cost_filters = {
    Service = "AmazonSageMaker"
  }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "FORECASTED"

    subscriber {
      address          = "finops-team@example.com"
      subscription_type = "EMAIL"
    }
  }
}
