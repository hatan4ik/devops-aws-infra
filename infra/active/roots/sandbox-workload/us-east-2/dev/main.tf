module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=c0fa6b65f35b1a3c11f64959a753af6bfe8e256e" # v0.1.0

  environment     = var.environment
  root            = "sandbox-workload"
  repository      = local.platform_context.repository
  name_components = ["sandbox", "workload", var.environment]
  additional_names = {
    network  = ["sandbox", "network", var.environment]
    platform = ["sandbox", "platform", var.environment]
  }
  base_tags = tomap(local.platform_context.base_tags)
}

module "sandbox_workload" {
  source = "git::https://github.com/hatan4ik/aws.modules.ecs-service.git?ref=5cfbc10026bf6a5b2d271f336718efe959b697a2" # v0.1.0

  name                         = module.naming.name_prefix
  cluster_arn                  = data.aws_ecs_cluster.platform.arn
  cluster_name                 = data.aws_ecs_cluster.platform.cluster_name
  vpc_id                       = data.aws_vpc.sandbox.id
  vpc_cidr                     = data.aws_vpc.sandbox.cidr_block
  private_subnet_ids           = toset(data.aws_subnets.private.ids)
  application_data_kms_key_arn = data.aws_kms_alias.application_data.target_key_arn
  log_retention_in_days        = var.log_retention_in_days
  cognito_user_pool_id         = var.cognito_user_pool_id
  session_table_arn            = data.aws_dynamodb_table.session.arn
  applications                 = var.applications
  tags                         = module.naming.tags
}
