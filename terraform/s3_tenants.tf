# Example: 2 tenants
variable "tenants" {
  default = ["tenant-a", "tenant-b"]
}

resource "aws_s3_bucket" "tenant_buckets" {
  for_each = toset(var.tenants)
  bucket   = "${each.key}-${var.project}-fraud-data"

  tags = {
    Project = var.project
    Tenant  = each.key
  }
}

resource "aws_iam_policy" "tenant_bucket_policy" {
  for_each = toset(var.tenants)
  name     = "${each.key}-${var.project}-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = [
          aws_s3_bucket.tenant_buckets[each.key].arn,
          "${aws_s3_bucket.tenant_buckets[each.key].arn}/*"
        ]
      }
    ]
  })
}

# Attach to tenant-specific execution role
resource "aws_iam_role_policy_attachment" "tenant_bucket_attach" {
  for_each   = toset(var.tenants)
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = aws_iam_policy.tenant_bucket_policy[each.key].arn
}
