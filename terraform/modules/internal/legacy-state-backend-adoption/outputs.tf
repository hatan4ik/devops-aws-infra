output "backend_identity" {
  description = "Non-secret identifiers used only by the approved canonical state-migration runbook."
  value = {
    bucket_name         = aws_s3_bucket.state.bucket
    dynamodb_table_name = aws_dynamodb_table.state_lock.name
    kms_key_alias       = aws_kms_alias.state.name
  }
}
