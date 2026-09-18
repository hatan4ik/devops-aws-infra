output "s3_bucket_id" {
  description = "The ID of the S3 bucket used for state storage."
  value       = module.tf_state_backend.s3_bucket_id
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for state locking."
  value       = module.tf_state_backend.dynamodb_table_name
}
