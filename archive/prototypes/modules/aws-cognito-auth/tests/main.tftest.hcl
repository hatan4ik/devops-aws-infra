# This historical module must stay unavailable as a deployment dependency.
mock_provider "aws" {}

run "prototype_is_disabled" {
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

  expect_failures = [terraform_data.prototype_disabled]
}
