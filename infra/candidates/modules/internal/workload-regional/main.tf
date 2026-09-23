module "vpc" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git//modules/workload?ref=ada254e7327ff9f401df41c0819a34fc7891938f" # v0.3.0

  name                               = var.workload_name
  ipv4_ipam_pool_id                  = var.vpc.ipv4_ipam_pool_id
  ipv4_netmask_length                = var.vpc.ipv4_netmask_length
  availability_zones                 = var.vpc.availability_zones
  transit_gateway_attachment_subnets = var.vpc.transit_gateway_attachment_subnets
  transit_gateway_routes             = var.vpc.transit_gateway_routes
  interface_endpoints                = var.vpc.interface_endpoints
  gateway_endpoints                  = var.vpc.gateway_endpoints
  flow_log_kms_key_arn               = var.vpc.flow_log_kms_key_arn
  flow_log_retention_in_days         = var.vpc.flow_log_retention_in_days
  tags                               = var.tags
}

# This creates only the workload-side attachment. The separate Network account
# composition accepts it and assigns association/propagation; no workload
# input can choose a TGW route domain.
module "transit_gateway_attachment" {
  for_each = var.transit_gateway_attachment == null ? {} : { requested = var.transit_gateway_attachment }

  source = "git::https://github.com/hatan4ik/aws.modules.tgw.git//modules/vpc-attachment?ref=886043384c3bc1637ed9b64e72d2af87d172d52e" # v0.2.0

  name                   = "${var.workload_name}-tgw"
  transit_gateway_id     = each.value.transit_gateway_id
  vpc_id                 = module.vpc.vpc.id
  subnet_ids             = toset([for subnet in values(module.vpc.transit_gateway_attachment_subnets) : subnet.id])
  attachment_key         = each.value.attachment_key
  appliance_mode_support = each.value.appliance_mode_support
  tags                   = var.tags

  depends_on = [terraform_data.transit_gateway_contract]
}

resource "terraform_data" "transit_gateway_contract" {
  input = {
    attachment = var.transit_gateway_attachment
    subnets    = var.vpc.transit_gateway_attachment_subnets
    routes     = var.vpc.transit_gateway_routes
  }

  lifecycle {
    precondition {
      condition     = var.transit_gateway_attachment != null || length(var.vpc.transit_gateway_routes) == 0
      error_message = "transit_gateway_routes require a workload-side Transit Gateway attachment."
    }

    precondition {
      condition     = var.transit_gateway_attachment == null || length(var.vpc.transit_gateway_attachment_subnets) >= 2
      error_message = "A workload-side Transit Gateway attachment requires dedicated transit subnets in at least two Availability Zones."
    }

    precondition {
      condition = var.transit_gateway_attachment == null || alltrue([
        for route in values(var.vpc.transit_gateway_routes) :
        route.transit_gateway_id == try(var.transit_gateway_attachment.transit_gateway_id, "")
      ])
      error_message = "Every workload TGW route must target the same approved Transit Gateway as the attachment."
    }
  }
}

module "cognito_primary" {
  for_each = var.identity.mode == "primary" ? { primary = var.identity.user_pool } : {}

  source = "git::https://github.com/hatan4ik/aws.modules.cognito.git?ref=5d605eff1d5cdabf84b6f525ed56e0057b84152d" # v0.1.1

  name                = each.value.name
  feature_plan        = each.value.feature_plan
  deletion_protection = each.value.deletion_protection
  mfa_configuration   = each.value.mfa_configuration
  password_policy     = each.value.password_policy
  clients             = each.value.clients
  resource_servers    = each.value.resource_servers
  tags                = var.tags
}
