data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

check "approved_sandbox_delivery_context" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
    error_message = "The sandbox-delivery root must run in its approved sandbox account."
  }

  assert {
    condition     = data.aws_region.current.region == var.aws_region
    error_message = "The sandbox-delivery root must run in its approved Region."
  }
}
