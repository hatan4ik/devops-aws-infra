module "vpc" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git//modules/workload?ref=abaaa401a45f3e3587d0e072c667b79a2ed9cf34" # v0.1.1

  name                       = var.workload_name
  ipv4_ipam_pool_id          = var.vpc.ipv4_ipam_pool_id
  ipv4_netmask_length        = var.vpc.ipv4_netmask_length
  availability_zones         = var.vpc.availability_zones
  interface_endpoints        = var.vpc.interface_endpoints
  gateway_endpoints          = var.vpc.gateway_endpoints
  flow_log_kms_key_arn       = var.vpc.flow_log_kms_key_arn
  flow_log_retention_in_days = var.vpc.flow_log_retention_in_days
  tags                       = var.tags
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
