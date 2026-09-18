module "state_backend" {
  source = "../../../../modules/internal/state-backend"

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
