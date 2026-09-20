module "legacy_state_backend" {
  source = "../../../../modules/internal/legacy-state-backend-adoption"

  bucket_name         = var.bucket_name
  dynamodb_table_name = var.dynamodb_table_name
  kms_key_alias       = var.kms_key_alias
  kms_key_description = var.kms_key_description
  tags                = var.tags
}

# These declarations make the one-time state-address migration reviewable in
# a Terraform plan. They do not execute until an approved operator applies a
# reviewed plan against the protected existing backend.
moved {
  from = module.tf_state_backend.aws_kms_key.state
  to   = module.legacy_state_backend.aws_kms_key.state
}

moved {
  from = module.tf_state_backend.aws_kms_alias.state
  to   = module.legacy_state_backend.aws_kms_alias.state
}

moved {
  from = module.tf_state_backend.aws_s3_bucket.state
  to   = module.legacy_state_backend.aws_s3_bucket.state
}

moved {
  from = module.tf_state_backend.aws_s3_bucket_public_access_block.state
  to   = module.legacy_state_backend.aws_s3_bucket_public_access_block.state
}

moved {
  from = module.tf_state_backend.aws_s3_bucket_versioning.state
  to   = module.legacy_state_backend.aws_s3_bucket_versioning.state
}

moved {
  from = module.tf_state_backend.aws_s3_bucket_server_side_encryption_configuration.state
  to   = module.legacy_state_backend.aws_s3_bucket_server_side_encryption_configuration.state
}

moved {
  from = module.tf_state_backend.aws_s3_bucket_object_lock_configuration.state
  to   = module.legacy_state_backend.aws_s3_bucket_object_lock_configuration.state
}

moved {
  from = module.tf_state_backend.aws_dynamodb_table.lock
  to   = module.legacy_state_backend.aws_dynamodb_table.state_lock
}

import {
  to = module.legacy_state_backend.aws_s3_bucket_ownership_controls.state
  id = var.bucket_name
}

removed {
  from = module.tf_state_backend.random_id.bucket_suffix

  lifecycle {
    destroy = false
  }
}
