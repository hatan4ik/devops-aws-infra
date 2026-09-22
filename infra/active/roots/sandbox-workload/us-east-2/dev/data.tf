data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "sandbox" {
  filter {
    name   = "tag:Name"
    values = [module.naming.names.network]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sandbox.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

data "aws_ecs_cluster" "platform" {
  cluster_name = "${module.naming.names.platform}-cluster"
}

data "aws_kms_alias" "application_data" {
  name = "alias/${module.naming.names.platform}-application-data"
}

data "aws_dynamodb_table" "session" {
  name = "${module.naming.names.platform}-session"
}

data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket = local.platform_context.terraform_state.sandbox_platform.bucket
    key    = local.platform_context.terraform_state.sandbox_platform.key
    region = local.platform_context.terraform_state.sandbox_platform.region
  }
}

check "approved_sandbox_workload_context" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
    error_message = "The sandbox-workload root must run in its approved sandbox account."
  }

  assert {
    condition     = data.aws_region.current.region == var.aws_region
    error_message = "The sandbox-workload root must run in its approved Region."
  }

  assert {
    condition     = length(data.aws_subnets.private.ids) >= 2
    error_message = "The sandbox-workload root requires two tagged private subnets."
  }
}
