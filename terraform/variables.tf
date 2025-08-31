variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "project" {
  description = "Project prefix"
  default     = "fraud-detection"
}

variable "sagemaker_endpoint_name" {
  description = "Name of deployed SageMaker endpoint"
  default     = "fraud-detection-prod"
}

variable "repo_name" {
  description = "Source repository for pipeline"
  default     = "fraud-detection-mlops"
}

variable "repo_branch" {
  description = "Branch for pipeline"
  default     = "main"
}

variable "sm_pipeline_role_arn" {
  description = "IAM role ARN for SageMaker pipeline"
  default     = ""
}

variable "sagemaker_endpoint_name" {
  description = "Name of deployed SageMaker endpoint"
  default     = "fraud-detection-prod"
}

variable "alert_email" {
  description = "Email address for Guardrail alerts"
  default     = "alerts@example.com"
}



variable "slack_webhook_url" {
  description = "Slack webhook for rollback notifications"
  type        = string
  default     = ""
}

variable "teams_webhook_url" {
  description = "Teams webhook for rollback notifications"
  type        = string
  default     = ""
}