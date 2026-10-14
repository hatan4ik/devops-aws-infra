terraform {
  required_version = ">= 1.7.0, < 2.0.0"
}

# These guardrails are deliberately local Terraform checks, not pretend SCPs.
# Organizations, IAM Identity Center, SCP enforcement, TGW sharing, VPN/BGP,
# and multi-account isolation need real AWS integration evidence.
check "us_only" {
  assert {
    condition     = startswith(var.primary_region, "us-")
    error_message = "The local catalog intentionally models only United States regions."
  }
}

check "two_zone_network" {
  assert {
    condition     = length(var.availability_zones) >= 2
    error_message = "The platform baseline requires at least two Availability Zones."
  }
}

check "no_real_account_identity" {
  assert {
    condition     = var.account_id == "000000000000"
    error_message = "The local catalog must never be configured with a real AWS account ID."
  }
}
