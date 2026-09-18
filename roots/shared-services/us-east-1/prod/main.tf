module "tf_state_backend" {
  source = "../../../../modules/aws-tf-state-backend"

  config = {
    bucket_prefix = var.state_bucket_prefix
    table_name    = var.state_lock_table_name
    environment   = "shared"
    tags          = var.tags
  }
}

