# Terraform support for QuickSight is limited. Here’s a stub:
resource "aws_quicksight_data_source" "rollback_logs" {
  data_source_id = "${var.project}-rollback-ds"
  name           = "${var.project}-rollback-ds"
  type           = "S3"

  parameters {
    s3 {
      manifest_file_location {
        bucket = aws_s3_bucket.rollback_logs_archive.bucket
        key    = "manifest.json"
      }
    }
  }

  permissions {
    principal = var.quicksight_principal_arn
    actions   = ["quicksight:DescribeDataSource", "quicksight:PassDataSource"]
  }
}
