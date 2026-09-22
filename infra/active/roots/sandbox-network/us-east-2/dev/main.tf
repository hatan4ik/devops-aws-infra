module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=v0.1.0"

  environment     = var.environment
  root            = "sandbox-network"
  repository      = local.platform_context.repository
  name_components = ["sandbox", "network", var.environment]
  base_tags       = tomap(local.platform_context.base_tags)
}

module "sandbox_network" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git?ref=v0.1.1"

  name                       = module.naming.name_prefix
  vpc_cidr                   = var.vpc_cidr
  availability_zones         = var.availability_zones
  private_subnet_cidrs       = var.private_subnet_cidrs
  flow_log_retention_in_days = var.flow_log_retention_in_days
  tags                       = module.naming.tags
}
