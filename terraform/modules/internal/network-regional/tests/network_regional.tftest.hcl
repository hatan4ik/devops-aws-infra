mock_provider "aws" {}

variables {
  name            = "test-network-use1"
  amazon_side_asn = 64512
  ram_principal_arns = [
    "arn:aws:organizations::111122223333:organization/o-example",
  ]
}

run "composes_the_segmented_tgw_hub" {
  command = plan

  assert {
    condition     = length(module.transit_gateway_hub.route_table_ids) == 5
    error_message = "The regional network composition must retain all TGW route domains."
  }
}
