mock_provider "aws" {}

variables {
  name_prefix = "test-platform"
  state_tiers = {
    dev = {
      bucket_name                                  = "test-platform-dev-tfstate"
      noncurrent_version_expiration_in_days        = 30
      abort_incomplete_multipart_upload_after_days = 7
      object_lock = {
        enabled = false
      }
    }
    staging = {
      bucket_name                                  = "test-platform-staging-tfstate"
      noncurrent_version_expiration_in_days        = 30
      abort_incomplete_multipart_upload_after_days = 7
      object_lock = {
        enabled        = true
        retention_mode = "GOVERNANCE"
        retention_days = 30
      }
    }
    prod = {
      bucket_name                                  = "test-platform-prod-tfstate"
      noncurrent_version_expiration_in_days        = 30
      abort_incomplete_multipart_upload_after_days = 7
      object_lock = {
        enabled        = true
        retention_mode = "COMPLIANCE"
        retention_days = 30
      }
    }
  }
  state_access_principal_arns = [
    "arn:aws:iam::111122223333:role/ci-terraform",
    "arn:aws:iam::111122223333:role/break-glass",
  ]
  kms_key_deletion_window_in_days = 30
  key_administrator_arns = [
    "arn:aws:iam::111122223333:role/key-admin",
  ]
}

run "plans_one_encrypted_versioned_backend_per_tier" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket.state) == 3 && length(aws_dynamodb_table.state_lock) == 3 && length(aws_kms_key.state) == 3
    error_message = "Every environment tier must have one isolated state bucket, lock table, and KMS key."
  }

  assert {
    condition = (
      alltrue([for configuration in aws_s3_bucket_versioning.state["prod"].versioning_configuration : configuration.status == "Enabled"]) &&
      alltrue(flatten([for rule in aws_s3_bucket_server_side_encryption_configuration.state["prod"].rule : [for encryption in rule.apply_server_side_encryption_by_default : encryption.sse_algorithm == "aws:kms"]]))
    )
    error_message = "Production state must be versioned and encrypted with SSE-KMS."
  }

  assert {
    condition     = length(aws_s3_bucket_object_lock_configuration.state) == 2
    error_message = "Only tiers explicitly configured for Object Lock may receive an Object Lock rule."
  }
}

run "rejects_missing_environment_tier" {
  command = plan

  variables {
    state_tiers = {
      dev = {
        bucket_name                                  = "test-platform-dev-tfstate"
        noncurrent_version_expiration_in_days        = 30
        abort_incomplete_multipart_upload_after_days = 7
        object_lock = {
          enabled = false
        }
      }
      prod = {
        bucket_name                                  = "test-platform-prod-tfstate"
        noncurrent_version_expiration_in_days        = 30
        abort_incomplete_multipart_upload_after_days = 7
        object_lock = {
          enabled = false
        }
      }
    }
  }

  expect_failures = [var.state_tiers]
}
