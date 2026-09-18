mock_provider "aws" {}

variables {
  workload_name = "test-workload-use1"
  vpc = {
    ipv4_ipam_pool_id   = "ipam-pool-0123abcd"
    ipv4_netmask_length = 20
    availability_zones = {
      use1-az1 = {
        availability_zone = "us-east-1a"
        subnet_newbits    = 2
        subnet_netnum     = 0
      }
      use1-az2 = {
        availability_zone = "us-east-1b"
        subnet_newbits    = 2
        subnet_netnum     = 1
      }
    }
    interface_endpoints = {}
    gateway_endpoints = {
      s3 = {
        service_name = "com.amazonaws.us-east-1.s3"
      }
    }
    flow_log_kms_key_arn       = "arn:aws:kms:us-east-1:111122223333:key/11111111-1111-1111-1111-111111111111"
    flow_log_retention_in_days = 30
  }
  identity = {
    mode      = "secondary"
    user_pool = null
  }
}

run "plans_secondary_private_vpc_without_independent_user_pool" {
  command = plan

  assert {
    condition     = length(module.vpc.private_subnets) == 2 && output.primary_user_pool == null
    error_message = "A secondary regional root must have private subnets and must not create a divergent independent user pool."
  }

  assert {
    condition     = output.identity_replication_status.status == "blocked-provider-support"
    error_message = "The MRR provider-support gap must remain explicit."
  }
}

run "rejects_secondary_with_independent_pool" {
  command = plan

  variables {
    identity = {
      mode = "secondary"
      user_pool = {
        name                = "invalid-secondary-pool"
        feature_plan        = "ESSENTIALS"
        deletion_protection = true
        mfa_configuration   = "ON"
        password_policy = {
          minimum_length                   = 14
          temporary_password_validity_days = 7
        }
        clients          = {}
        resource_servers = {}
      }
    }
  }

  expect_failures = [var.identity]
}
