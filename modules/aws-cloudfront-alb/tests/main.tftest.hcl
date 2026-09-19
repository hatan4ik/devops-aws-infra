# This historical module must stay unavailable as a deployment dependency.
mock_provider "aws" {}

run "prototype_is_disabled" {
  command = plan

  variables {
    config = {
      name               = "test-cf"
      environment        = "dev"
      primary_alb_domain = "alb1.example.com"
    }
  }

  expect_failures = [terraform_data.prototype_disabled]
}
