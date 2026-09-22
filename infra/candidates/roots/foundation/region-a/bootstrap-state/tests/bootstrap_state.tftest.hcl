mock_provider "aws" {}

# Import blocks cannot call a mock provider. Override the imported ownership
# control so this test still exercises the root contract without AWS access.
override_resource {
  target = module.legacy_state_backend.aws_s3_bucket_ownership_controls.state
}

variables {
  aws_region          = "us-east-2"
  aws_account_id      = "111122223333"
  bucket_name         = "test-platform-tf-state"
  dynamodb_table_name = "test-platform-tf-lock"
  kms_key_alias       = "alias/test-platform-terraform-state"
  kms_key_description = "Test legacy Terraform state key"
  tags = {
    Environment = "shared"
    Layer       = "shared-services"
    ManagedBy   = "Terraform"
    Module      = "legacy-state-backend-adoption"
    Project     = "platform-aws-platform"
  }
}

run "plans_transitional_backend_contract" {
  command = plan

  assert {
    condition     = contains(keys(output.backend_configuration.legacy), "bucket") && contains(keys(output.state_access_policy_arns.legacy), "lock_arn")
    error_message = "The root must expose the transitional backend contract."
  }
}

run "rejects_an_invalid_account_id" {
  command = plan

  variables {
    aws_account_id = "invalid"
  }

  expect_failures = [var.aws_account_id]
}
