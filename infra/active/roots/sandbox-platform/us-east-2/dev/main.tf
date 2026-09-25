module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=c0fa6b65f35b1a3c11f64959a753af6bfe8e256e" # v0.1.0

  environment     = var.environment
  root            = "sandbox-platform"
  repository      = local.platform_context.repository
  name_components = ["sandbox", "platform", var.environment]
  additional_names = {
    network  = ["sandbox", "network", var.environment]
    workload = ["sandbox", "workload", var.environment]
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

module "cognito" {
  source = "git::https://github.com/hatan4ik/aws.modules.cognito.git?ref=67dab780e709293970bc0092ef882d93ebc479ea" # PRE-RELEASE pin — re-pin to the v1.0.0 tag once PR #1 is merged and released

  name                = "${module.naming.name_prefix}-users"
  feature_plan        = "ESSENTIALS"
  deletion_protection = true
  mfa_configuration   = "OPTIONAL"
  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
  }
  clients          = {}
  resource_servers = {}
  tags             = module.naming.tags
}

module "sandbox_platform_core" {
  source = "git::https://github.com/hatan4ik/aws.modules.ecs.git?ref=e38e9c5f55db3001bb66ef3be095aa446ff62c31" # PRE-RELEASE pin — re-pin to the v1.0.0 tag once PR #2 is merged and released

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
  # Preserves the live security group's existing (immutable) description
  # exactly; v1's own default text differs by one word and would otherwise
  # force a destroy/recreate of this group during migration.
  interface_endpoint_security_group_description = "Accepts TLS only from the sandbox VPC to AWS PrivateLink endpoints."
  log_retention_in_days                         = var.log_retention_in_days
  additional_cloudwatch_log_group_arns = toset([
    "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/${module.naming.names.workload}/*",
  ])
  tags = module.naming.tags

  depends_on = [terraform_data.network_contract]
}
