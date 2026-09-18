output "s3_bucket_id" {
  description = "The ID of the S3 bucket used for state storage."
  value       = aws_s3_bucket.state.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for state storage."
  value       = aws_s3_bucket.state.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for state locking."
  value       = aws_dynamodb_table.lock.name
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encrypting the state bucket and lock table."
  value       = aws_kms_key.state.arn
}
