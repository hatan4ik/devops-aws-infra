module "vpc" {
  source = "../../../../modules/aws-vpc-workload"

  config = {
    vpc_name             = var.vpc_name
    environment          = var.environment
    ipv4_ipam_pool_id    = var.ipv4_ipam_pool_id
    ipv4_netmask_length  = var.ipv4_netmask_length
    azs                  = var.azs
    enable_nat_gateway   = var.enable_nat_gateway
    enable_vpc_endpoints = true
    tags                 = var.tags
  }
}
