module "transit_gateway_hub" {
  source = "git::https://github.com/hatan4ik/aws.modules.tgw.git?ref=886043384c3bc1637ed9b64e72d2af87d172d52e" # v0.2.0

  name                             = var.name
  amazon_side_asn                  = var.amazon_side_asn
  route_domains                    = var.route_domains
  ram_principals                   = var.ram_principals
  flow_log_retention_in_days       = var.flow_log_retention_in_days
  rejected_traffic_alarm_threshold = var.rejected_traffic_alarm_threshold
  rejected_traffic_alarm_actions   = var.rejected_traffic_alarm_actions
  tags                             = var.tags
}

# Attachment acceptance, route-table association, and propagation belong only
# to the Network account. A spoke may create an attachment, but it cannot use
# tags or inputs to select its own route domain.
module "network_routing" {
  for_each = var.routing == null ? {} : { approved = var.routing }

  source = "git::https://github.com/hatan4ik/aws.modules.tgw.git//modules/network-routing?ref=886043384c3bc1637ed9b64e72d2af87d172d52e" # v0.2.0

  route_table_ids          = module.transit_gateway_hub.route_table_ids
  approved_account_domains = each.value.approved_account_domains
  attachments              = each.value.attachments
  propagation_matrix       = each.value.propagation_matrix
  static_routes            = each.value.static_routes
  tags                     = var.tags

  depends_on = [terraform_data.route_policy]
}

# The default policy has separate prod and non-prod domains. Their direct
# propagation is prohibited even if a configuration author accidentally
# supplies it. Intentional exceptions need a reviewed module/ADR change.
resource "terraform_data" "route_policy" {
  input = var.routing

  lifecycle {
    precondition {
      condition = var.routing == null || (
        !contains(try(var.routing.propagation_matrix["prod"], []), "non-prod") &&
        !contains(try(var.routing.propagation_matrix["non-prod"], []), "prod")
      )
      error_message = "The Network routing policy must not directly propagate prod routes into non-prod, or non-prod routes into prod."
    }
  }
}
