module "sandbox_network" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git?ref=v0.1.1"

  name                       = var.network_name
  vpc_cidr                   = var.vpc_cidr
  availability_zones         = var.availability_zones
  private_subnet_cidrs       = var.private_subnet_cidrs
  flow_log_retention_in_days = var.flow_log_retention_in_days
  tags                       = local.default_tags
}
