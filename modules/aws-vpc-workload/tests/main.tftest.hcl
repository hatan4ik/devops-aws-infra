# Terraform Test for aws-vpc-workload module

mock_provider "aws" {}

run "valid_configuration" {
  command = plan

  variables {
    config = {
      vpc_name             = "test-vpc"
      environment          = "dev"
      ipv4_ipam_pool_id    = "ipam-pool-123"
      ipv4_netmask_length  = 20
      azs                  = ["us-east-2a", "us-east-2b"]
    }
  }

  assert {
    condition     = length(aws_subnet.private_app) == 2
    error_message = "Should create exactly 2 private app subnets."
  }
}

run "invalid_environment" {
  command = plan

  variables {
    config = {
      vpc_name             = "test-vpc"
      environment          = "invalid"
      ipv4_ipam_pool_id    = "ipam-pool-123"
      ipv4_netmask_length  = 20
      azs                  = ["us-east-2a", "us-east-2b"]
    }
  }

  expect_failures = [
    var.config
  ]
}

run "insufficient_azs" {
  command = plan

  variables {
    config = {
      vpc_name             = "test-vpc"
      environment          = "dev"
      ipv4_ipam_pool_id    = "ipam-pool-123"
      ipv4_netmask_length  = 20
      azs                  = ["us-east-2a"]
    }
  }

  expect_failures = [
    var.config
  ]
}

