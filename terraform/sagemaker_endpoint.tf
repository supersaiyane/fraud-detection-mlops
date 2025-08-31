# -------------------------------------------------------
# SageMaker Model (deployed from registry package)
# -------------------------------------------------------
resource "aws_sagemaker_model" "fraud_model" {
  name          = "${var.project}-model"
  execution_role_arn = aws_iam_role.sagemaker_pipeline_role.arn

  primary_container {
    image          = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.5-1" # region specific
    model_data_url = "s3://${aws_s3_bucket.fraud_data.bucket}/models/xgb_model.tar.gz"
  }
}

# -------------------------------------------------------
# Endpoint Config with Canary
# -------------------------------------------------------
resource "aws_sagemaker_endpoint_configuration" "fraud_endpoint_config" {
  name = "${var.project}-endpoint-config"

  production_variants {
    variant_name          = "ProdVariant"
    model_name            = aws_sagemaker_model.fraud_model.name
    initial_instance_count = 1
    instance_type         = "ml.m5.large"
    initial_variant_weight = 0.9
  }

  production_variants {
    variant_name          = "CanaryVariant"
    model_name            = aws_sagemaker_model.fraud_model.name
    initial_instance_count = 1
    instance_type         = "ml.m5.large"
    initial_variant_weight = 0.1
  }
}

# -------------------------------------------------------
# SageMaker Endpoint
# -------------------------------------------------------
resource "aws_sagemaker_endpoint" "fraud_endpoint" {
  name                 = var.sagemaker_endpoint_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.fraud_endpoint_config.name
}
