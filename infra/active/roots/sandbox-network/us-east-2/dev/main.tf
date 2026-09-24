module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=c0fa6b65f35b1a3c11f64959a753af6bfe8e256e" # v0.1.0

  environment     = var.environment
  root            = "sandbox-network"
  repository      = local.platform_context.repository
  name_components = ["sandbox", "network", var.environment]
  base_tags       = tomap(local.platform_context.base_tags)
}

module "sandbox_network" {
  # Pre-release pin for plan verification; replaced by the v1.0.0 release commit before merge.
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git?ref=e6f697f5e60f358574e6db595ed42b022cd8527f" # v1.0.0

  name       = module.naming.name_prefix
  cidr_block = var.vpc_cidr
  tags       = module.naming.tags

  # v1 enables Network Address Usage metrics by default; the sandbox VPC was
  # created without them, so keep them off to leave the resource untouched.
  enable_network_address_usage_metrics = false

  subnets = {
    private = {
      availability_zones = {
        for key, zone in var.availability_zones : key => {
          availability_zone = zone
          cidr_block        = var.private_subnet_cidrs[key]
        }
      }
    }
  }

  flow_logs = {
    destination       = { create_kms_key = true }
    retention_in_days = var.flow_log_retention_in_days
    partition         = "aws"
    region            = var.aws_region
    account_id        = var.aws_account_id
  }
}
