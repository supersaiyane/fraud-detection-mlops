resource "aws_s3_bucket" "txn_logs" {
  bucket = "${var.project}-txn-logs"
}

resource "aws_s3_bucket_lifecycle_configuration" "txn_logs_lifecycle" {
  bucket = aws_s3_bucket.txn_logs.id

  rule {
    id     = "archive-logs"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555 # ~7 years
    }
  }
}
