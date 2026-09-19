mock_provider "aws" {}

run "valid_configuration" {
  command = plan

  variables {
    config = {
      pool_name              = "test-pool"
      environment            = "dev"
      domain_prefix          = "platform-auth"
      callback_urls          = ["https://localhost/callback"]
      logout_urls            = ["https://localhost/logout"]
      advanced_security_mode = "ENFORCED"
      enable_mfa             = "ON"
    }
  }

  assert {
    condition     = aws_cognito_user_pool.this.name == "test-pool"
    error_message = "User pool name mismatch."
  }
}

run "invalid_advanced_security" {
  command = plan

  variables {
    config = {
      pool_name              = "test-pool"
      environment            = "dev"
      domain_prefix          = "platform-auth"
      callback_urls          = ["https://localhost/callback"]
      logout_urls            = ["https://localhost/logout"]
      advanced_security_mode = "INVALID"
      enable_mfa             = "ON"
    }
  }

  expect_failures = [
    var.config
  ]
}
