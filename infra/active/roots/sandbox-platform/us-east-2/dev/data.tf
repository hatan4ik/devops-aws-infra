data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

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

data "aws_route_tables" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sandbox.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

check "approved_sandbox_platform_context" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
    error_message = "The sandbox-platform root must run in its approved sandbox account."
  }

  assert {
    condition     = data.aws_region.current.region == var.aws_region
    error_message = "The sandbox-platform root must run in its approved Region."
  }
}
