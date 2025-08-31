output "s3_bucket_name" {
  value = aws_s3_bucket.fraud_data.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.fraud_txns.name
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.fraud_stage.invoke_url
}
