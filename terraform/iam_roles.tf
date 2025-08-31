resource "aws_iam_role_policy" "fraud_lambda_policy" {
  name = "${var.project}-fraud-lambda-policy"
  role = aws_iam_role.fraud_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sagemaker:InvokeEndpoint"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.fraud_txns.arn
      }
    ]
  })
}
