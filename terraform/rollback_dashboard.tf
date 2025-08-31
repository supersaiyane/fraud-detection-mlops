# -------------------------------------------------------
# Enable DynamoDB Streams on Rollback Logs
# -------------------------------------------------------
resource "aws_dynamodb_table" "rollback_logs" {
  name         = "${var.project}-rollback-logs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "rollback_id"

  attribute {
    name = "rollback_id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

# -------------------------------------------------------
# S3 Bucket for Rollback Logs Archive
# -------------------------------------------------------
resource "aws_s3_bucket" "rollback_logs_archive" {
  bucket        = "${var.project}-rollback-logs-archive"
  force_destroy = true
}

# -------------------------------------------------------
# Kinesis Firehose to S3
# -------------------------------------------------------
resource "aws_iam_role" "firehose_role" {
  name = "${var.project}-firehose-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_s3" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_kinesis_firehose_delivery_stream" "rollback_firehose" {
  name        = "${var.project}-rollback-firehose"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.rollback_logs_archive.arn
  }
}

# -------------------------------------------------------
# CloudWatch Dashboard
# -------------------------------------------------------
resource "aws_cloudwatch_dashboard" "rollback_dashboard" {
  dashboard_name = "${var.project}-rollback-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          title = "SageMaker Endpoint Latency",
          metrics = [
            ["AWS/SageMaker", "ModelLatency", "EndpointName", var.sagemaker_endpoint_name]
          ],
          period = 60,
          stat   = "Average",
          region = var.region
        }
      },
      {
        type = "metric",
        x = 12,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          title = "Rollback Events (DynamoDB Inserts)",
          metrics = [
            ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", aws_dynamodb_table.rollback_logs.name]
          ],
          period = 300,
          stat   = "SampleCount",
          region = var.region
        }
      },
      {
        type = "metric",
        x = 0,
        y = 6,
        width = 24,
        height = 6,
        properties = {
          title = "API 5xx Errors",
          metrics = [
            ["AWS/ApiGateway", "5XXError", "ApiName", "${var.project}-fraud-api"]
          ],
          period = 60,
          stat   = "Sum",
          region = var.region
        }
      }
    ]
  })
}
