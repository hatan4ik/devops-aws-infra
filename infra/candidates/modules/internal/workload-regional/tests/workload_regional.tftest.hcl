mock_provider "aws" {}

variables {
  workload_name = "test-workload-use1"
  vpc = {
    ipv4_ipam_pool_id   = "ipam-pool-0123abcd"
    ipv4_netmask_length = 20
    availability_zones = {
      use1-az1 = {
        availability_zone = "us-east-2a"
        subnet_newbits    = 2
        subnet_netnum     = 0
      }
      use1-az2 = {
        availability_zone = "us-east-2b"
        subnet_newbits    = 2
        subnet_netnum     = 1
      }
    }
    transit_gateway_attachment_subnets = {
      use1-az1 = {
        subnet_newbits = 2
        subnet_netnum  = 2
      }
      use1-az2 = {
        subnet_newbits = 2
        subnet_netnum  = 3
      }
    }
    transit_gateway_routes = {
      on_prem = {
        destination_cidr_block = "10.250.0.0/16"
        transit_gateway_id     = "tgw-0123abcd"
      }
    }
    interface_endpoints = {}
    gateway_endpoints = {
      s3 = {
        service_name = "com.amazonaws.us-east-2.s3"
      }
    }
    flow_log_kms_key_arn       = "arn:aws:kms:us-east-2:111122223333:key/11111111-1111-1111-1111-111111111111"
    flow_log_retention_in_days = 365
  }
  transit_gateway_attachment = {
    transit_gateway_id = "tgw-0123abcd"
    attachment_key     = "workload-dev-use2"
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
    condition     = length(output.transit_gateway_attachment_subnets) == 2
    error_message = "A workload TGW attachment must use dedicated transit subnets in two Availability Zones."
  }

  assert {
    condition     = output.identity_replication_status.status == "blocked-provider-support"
    error_message = "The MRR provider-support gap must remain explicit."
  }
}

run "rejects_tgw_routes_without_an_attachment" {
  command = plan

  variables {
    transit_gateway_attachment = null
  }

  expect_failures = [terraform_data.transit_gateway_contract]
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
