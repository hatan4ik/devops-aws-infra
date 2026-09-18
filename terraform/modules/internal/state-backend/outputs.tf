output "backend_configuration" {
  description = "Non-secret S3 backend values for each environment tier. Configure both S3 lockfile and DynamoDB during the documented locking migration period."
  value = {
    for tier in keys(var.state_tiers) : tier => {
      bucket         = aws_s3_bucket.state[tier].id
      kms_key_id     = aws_kms_key.state[tier].arn
      dynamodb_table = aws_dynamodb_table.state_lock[tier].name
      use_lockfile   = true
    }
  }
}

output "state_access_policy_arns" {
  description = "State bucket and KMS ARNs to scope the CI and break-glass identity policies."
  value = {
    for tier in keys(var.state_tiers) : tier => {
      bucket_arn = aws_s3_bucket.state[tier].arn
      key_arn    = aws_kms_key.state[tier].arn
      lock_arn   = aws_dynamodb_table.state_lock[tier].arn
    }
  }
}
