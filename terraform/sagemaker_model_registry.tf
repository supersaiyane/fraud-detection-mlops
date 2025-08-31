# -------------------------------------------------------
# SageMaker Model Package Group (Model Registry)
# -------------------------------------------------------
resource "aws_sagemaker_model_package_group" "fraud_group" {
  model_package_group_name = "${var.project}-fraud-model-group"
  model_package_group_description = "Registry for Fraud Detection models"
  tags = {
    Project = var.project
    Owner   = "Principal Cloud Architect & SRE"
  }
}
