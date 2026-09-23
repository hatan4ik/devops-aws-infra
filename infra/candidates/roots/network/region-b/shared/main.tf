module "network_regional" {
  source = "../../../../modules/internal/network-regional"

  name                             = var.network.name
  amazon_side_asn                  = var.network.amazon_side_asn
  route_domains                    = var.network.route_domains
  ram_principals                   = var.network.ram_principals
  flow_log_retention_in_days       = var.network.flow_log_retention_in_days
  rejected_traffic_alarm_threshold = var.network.rejected_traffic_alarm_threshold
  rejected_traffic_alarm_actions   = var.network.rejected_traffic_alarm_actions
  routing                          = var.network.routing
  tags                             = local.default_tags

  depends_on = [terraform_data.regional_asn_policy]
}

resource "terraform_data" "regional_asn_policy" {
  input = {
    aws_region               = var.aws_region
    regional_region_registry = var.regional_region_registry
    regional_asn_registry    = var.regional_asn_registry
    amazon_side_asn          = var.network.amazon_side_asn
  }

  lifecycle {
    precondition {
      condition = (
        can(var.regional_region_registry["primary"]) &&
        can(var.regional_region_registry["secondary"]) &&
        var.regional_region_registry["primary"] != var.regional_region_registry["secondary"] &&
        var.aws_region == var.regional_region_registry["secondary"]
      )
      error_message = "The secondary Network root must use the secondary Region in a reviewed, distinct primary/secondary regional_region_registry."
    }

    precondition {
      condition     = length(distinct(values(var.regional_asn_registry))) == length(var.regional_asn_registry)
      error_message = "regional_asn_registry must assign a unique Amazon-side ASN to every deployed Regional TGW."
    }

    precondition {
      condition     = can(var.regional_asn_registry[var.aws_region]) && var.network.amazon_side_asn == var.regional_asn_registry[var.aws_region]
      error_message = "network.amazon_side_asn must match the reviewed regional_asn_registry entry for aws_region."
    }
  }
}
