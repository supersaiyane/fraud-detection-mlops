resource "aws_dynamodb_table" "fraud_txns" {
  name         = "${var.project}-fraud-txns"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "txn_id"

  attribute {
    name = "txn_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  tags = {
    Project = var.project
    Purpose = "SuspiciousTransactions"
  }
}
