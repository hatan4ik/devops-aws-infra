mock_provider "aws" {}

variables {
  name            = "test-network-use1"
  amazon_side_asn = 64512
  ram_principals  = ["111122223333"]
  routing = {
    approved_account_domains = {
      "111122223333" = "prod"
      "444455556666" = "non-prod"
    }
    attachments = {
      workload_prod = {
        attachment_id = "tgw-attach-0123abcd"
        account_id    = "111122223333"
      }
      workload_dev = {
        attachment_id = "tgw-attach-4567def0"
        account_id    = "444455556666"
      }
    }
    propagation_matrix = {
      prod       = ["shared", "inspection", "on-prem"]
      non-prod   = ["shared", "inspection", "on-prem"]
      shared     = ["prod", "non-prod", "inspection", "on-prem"]
      inspection = ["prod", "non-prod", "shared", "on-prem"]
      on-prem    = ["prod", "non-prod", "shared", "inspection"]
    }
    static_routes = {
      quarantine = {
        route_table_domain     = "prod"
        destination_cidr_block = "10.250.0.0/16"
        blackhole              = true
      }
    }
  }
}

run "composes_the_segmented_tgw_hub" {
  command = plan

  assert {
    condition     = length(module.transit_gateway_hub.route_table_ids) == 5
    error_message = "The regional network composition must retain all TGW route domains."
  }

  assert {
    condition     = module.network_routing["approved"].attachment_domains.workload_prod == "prod" && module.network_routing["approved"].attachment_domains.workload_dev == "non-prod"
    error_message = "Only the Network routing catalog may assign attachment domains."
  }
}

run "rejects_direct_prod_non_prod_propagation" {
  command = plan

  variables {
    routing = {
      approved_account_domains = {}
      attachments              = {}
      propagation_matrix = {
        prod       = ["non-prod"]
        non-prod   = []
        shared     = []
        inspection = []
        on-prem    = []
      }
    }
  }

  expect_failures = [terraform_data.route_policy]
}
