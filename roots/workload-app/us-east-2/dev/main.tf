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

module "ecs" {
  source = "../../../../modules/aws-ecs-fargate"
  
  config = {
    cluster_name = "${var.vpc_name}-cluster"
    environment  = var.environment
    tags         = var.tags
  }
}

module "auth" {
  source = "../../../../modules/aws-cognito-auth"
  
  config = {
    pool_name              = "${var.vpc_name}-users"
    environment            = var.environment
    domain_prefix          = "platform-auth-${var.environment}"
    callback_urls          = ["https://app.example.com/callback"]
    logout_urls            = ["https://app.example.com/logout"]
    advanced_security_mode = "ENFORCED"
    enable_mfa             = "ON"
    tags                   = var.tags
  }
}

