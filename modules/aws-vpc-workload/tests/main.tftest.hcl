# This historical module must stay unavailable as a deployment dependency.
mock_provider "aws" {}

run "prototype_is_disabled" {
  command = plan

  variables {
    config = {
      vpc_name            = "test-vpc"
      environment         = "dev"
      ipv4_ipam_pool_id   = "ipam-pool-123"
      ipv4_netmask_length = 20
      azs                 = ["us-east-2a", "us-east-2b"]
    }
  }

  expect_failures = [terraform_data.prototype_disabled]
}
