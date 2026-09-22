output "organization" {
  description = "Verified Organization contract used by this root."
  value = {
    id                   = data.aws_organizations_organization.current.id
    management_account   = data.aws_caller_identity.current.account_id
    root_id              = data.aws_organizations_organization.current.roots[0].id
    enabled_policy_types = data.aws_organizations_organization.current.enabled_policy_types
  }
}

output "organizational_units" {
  description = "Terraform-managed top-level OUs keyed by stable OU name."
  value = {
    for key, organizational_unit in aws_organizations_organizational_unit.platform : key => {
      arn = organizational_unit.arn
      id  = organizational_unit.id
    }
  }
}

output "baseline_policies" {
  description = "Terraform-managed baseline SCPs. They are attached to each platform OU, never the management-account root."
  value = {
    for key, policy in aws_organizations_policy.baseline : key => {
      arn = policy.arn
      id  = policy.id
    }
  }
}

output "vended_accounts" {
  description = "Only accounts explicitly present in the approved accounts tfvars map."
  value = {
    for key, account in aws_organizations_account.vended : key => {
      arn       = account.arn
      email     = account.email
      id        = account.id
      parent_id = account.parent_id
    }
  }
}
