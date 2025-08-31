resource "aws_api_gateway_rest_api" "fraud_api" {
  name        = "${var.project}-fraud-api"
  description = "Fraud detection public API"
}

resource "aws_api_gateway_resource" "fraud_check" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id
  parent_id   = aws_api_gateway_rest_api.fraud_api.root_resource_id
  path_part   = "fraud-check"
}

resource "aws_api_gateway_method" "post_fraud_check" {
  rest_api_id   = aws_api_gateway_rest_api.fraud_api.id
  resource_id   = aws_api_gateway_resource.fraud_check.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "fraud_lambda" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id
  resource_id = aws_api_gateway_resource.fraud_check.id
  http_method = aws_api_gateway_method.post_fraud_check.http_method
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.fraud_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "fraud_api" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id
  stage_name  = "prod"
}

# API Gateway WAF Web ACL
resource "aws_wafv2_web_acl" "fraud_api_waf" {
  name        = "${var.project}-fraud-api-waf"
  description = "Protect Fraud API"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "fraud-api-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "RateLimit"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "fraud-api-rate-limit"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "fraud_api_waf_assoc" {
  resource_arn = aws_api_gateway_stage.fraud_api_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.fraud_api_waf.arn
}

resource "aws_api_gateway_stage" "fraud_api_stage" {
  rest_api_id = aws_api_gateway_rest_api.fraud_api.id
  deployment_id = aws_api_gateway_deployment.fraud_api.id
  stage_name = "prod"
}


resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fraud_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fraud_api.execution_arn}/*/*"
}