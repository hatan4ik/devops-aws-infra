provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias               = "replica"
  region              = var.aws_replica_region
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = local.default_tags
  }
}
