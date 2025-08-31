# --------------------------------------
# SageMaker Pipeline IAM Role
# --------------------------------------
resource "aws_iam_role" "sagemaker_pipeline_role" {
  name = "${var.project}-sagemaker-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_pipeline_full" {
  role       = aws_iam_role.sagemaker_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# --------------------------------------
# SageMaker Pipeline Definition
# (JSON created by pipeline/sagemaker_pipeline.py)
# --------------------------------------
resource "aws_sagemaker_pipeline" "fraud_pipeline" {
  pipeline_name        = "${var.project}-sagemaker-pipeline"       # Required unique identifier
  pipeline_display_name = "Fraud Detection ML Pipeline"            # Required friendly display name
  role_arn             = aws_iam_role.sagemaker_pipeline_role.arn
  pipeline_definition  = file("${path.module}/../pipeline/sagemaker_pipeline.json")

  tags = {
    Project = var.project
    Owner   = "Principal Cloud Architect & SRE"
  }
}
