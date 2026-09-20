module "sandbox_network" {
  source = "../../../../modules/internal/sandbox-network"

  name                       = var.network_name
  vpc_cidr                   = var.vpc_cidr
  availability_zones         = var.availability_zones
  private_subnet_cidrs       = var.private_subnet_cidrs
  flow_log_retention_in_days = var.flow_log_retention_in_days
  tags                       = local.default_tags
}
