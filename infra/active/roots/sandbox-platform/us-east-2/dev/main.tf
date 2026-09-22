module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=c0fa6b65f35b1a3c11f64959a753af6bfe8e256e" # v0.1.0

  environment     = var.environment
  root            = "sandbox-platform"
  repository      = local.platform_context.repository
  name_components = ["sandbox", "platform", var.environment]
  additional_names = {
    network = ["sandbox", "network", var.environment]
  }
  base_tags = tomap(local.platform_context.base_tags)
}

resource "terraform_data" "network_contract" {
  input = {
    vpc_id                  = data.aws_vpc.sandbox.id
    private_subnet_ids      = data.aws_subnets.private.ids
    private_route_table_ids = data.aws_route_tables.private.ids
  }

  lifecycle {
    precondition {
      condition     = data.aws_vpc.sandbox.cidr_block == "10.64.0.0/16"
      error_message = "The sandbox platform core requires the approved 10.64.0.0/16 sandbox VPC."
    }

    precondition {
      condition     = length(data.aws_subnets.private.ids) >= 2 && length(data.aws_route_tables.private.ids) >= 2
      error_message = "The sandbox platform core requires two tagged private subnets and two tagged private route tables."
    }
  }
}

module "sandbox_platform_core" {
  source = "git::https://github.com/hatan4ik/aws.modules.ecs.git?ref=ea77826de488780e5fea63f31e0e7dc4da60638e" # v0.1.1

  name                    = module.naming.name_prefix
  vpc_id                  = data.aws_vpc.sandbox.id
  vpc_cidr                = data.aws_vpc.sandbox.cidr_block
  private_subnet_ids      = toset(data.aws_subnets.private.ids)
  private_route_table_ids = toset(data.aws_route_tables.private.ids)
  interface_endpoint_services = toset([
    "cognito-idp",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "sts",
  ])
  gateway_endpoint_services = toset(["dynamodb", "s3"])
  log_retention_in_days     = var.log_retention_in_days
  tags                      = module.naming.tags

  depends_on = [terraform_data.network_contract]
}
