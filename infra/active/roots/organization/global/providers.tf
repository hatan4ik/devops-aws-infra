provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.management_account_id]

  default_tags {
    tags = local.default_tags
  }
}
