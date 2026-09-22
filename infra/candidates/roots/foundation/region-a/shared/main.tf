data "aws_region" "primary" {}

data "aws_region" "replica" {
  provider = aws.replica
}

check "provider_region_binding" {
  assert {
    condition     = data.aws_region.primary.region == var.aws_region
    error_message = "The default AWS provider must be configured for aws_region."
  }

  assert {
    condition     = data.aws_region.replica.region == var.aws_replica_region
    error_message = "The aws.replica provider must be configured for aws_replica_region."
  }
}

module "state_backend" {
  source = "git::https://github.com/hatan4ik/aws.modules.state.git?ref=521f222211adb727d04f9dd6ff1fa4896e4b5719" # v0.1.0

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }

  name_prefix                     = var.state_backend.name_prefix
  primary_region                  = var.aws_region
  replica_region                  = var.aws_replica_region
  access_log_bucket_name          = var.state_backend.access_log_bucket_name
  access_log_prefix               = var.state_backend.access_log_prefix
  state_tiers                     = var.state_backend.state_tiers
  state_access_principal_arns     = var.state_backend.state_access_principal_arns
  kms_key_deletion_window_in_days = var.state_backend.kms_key_deletion_window_in_days
  key_administrator_arns          = var.state_backend.key_administrator_arns
  tags                            = local.default_tags
}
