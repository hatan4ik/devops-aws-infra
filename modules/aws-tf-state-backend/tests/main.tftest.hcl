# Terraform Test for aws-tf-state-backend module

mock_provider "aws" {}

run "valid_configuration" {
  command = plan

  variables {
    config = {
      bucket_prefix = "test-tf-state"
      table_name    = "test-tf-lock-table"
      environment   = "dev"
    }
  }

  assert {
    condition     = aws_s3_bucket.state.bucket != ""
    error_message = "Bucket name must be generated."
  }

  assert {
    condition     = aws_dynamodb_table.lock.name == "test-tf-lock-table"
    error_message = "DynamoDB table name must match input."
  }
}

# The brief required a failing validation case test
run "invalid_environment" {
  command = plan

  variables {
    config = {
      bucket_prefix = "test-tf-state"
      table_name    = "test-tf-lock-table"
      environment   = "invalid-env"
    }
  }

  expect_failures = [
    var.config
  ]
}

run "invalid_bucket_prefix_length" {
  command = plan

  variables {
    config = {
      bucket_prefix = "this-prefix-is-way-too-long-to-be-allowed-by-the-validation"
      table_name    = "test-tf-lock-table"
      environment   = "dev"
    }
  }

  expect_failures = [
    var.config
  ]
}

