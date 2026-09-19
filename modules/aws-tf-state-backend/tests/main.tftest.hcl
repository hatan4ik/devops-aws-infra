# This historical module must stay unavailable as a deployment dependency.
mock_provider "aws" {}

run "prototype_is_disabled" {
  command = plan

  variables {
    config = {
      bucket_prefix = "test-tf-state"
      table_name    = "test-tf-lock-table"
      environment   = "dev"
    }
  }

  expect_failures = [terraform_data.prototype_disabled]
}
