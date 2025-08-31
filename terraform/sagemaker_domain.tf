resource "aws_sagemaker_domain" "tenant_domain" {
  domain_name = "${var.project}-tenant-domain"
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  default_user_settings {
    execution_role = aws_iam_role.sagemaker_execution.arn
  }
}

# Example user profiles for tenants
resource "aws_sagemaker_user_profile" "tenant_ds" {
  domain_id         = aws_sagemaker_domain.tenant_domain.id
  user_profile_name = "datascientist-1"
  user_settings {
    execution_role = aws_iam_role.sagemaker_execution.arn
  }
}

# DataZone Domain (stub)
resource "aws_datazone_domain" "fraud_datazone" {
  name        = "${var.project}-datazone"
  description = "Governed dataset domain for fraud detection"
  domain_execution_role = aws_iam_role.sagemaker_execution.arn
}
