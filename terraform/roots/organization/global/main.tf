data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "current" {}

resource "terraform_data" "organization_contract" {
  input = {
    account_id      = data.aws_caller_identity.current.account_id
    organization_id = data.aws_organizations_organization.current.id
  }

  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.management_account_id
      error_message = "The direct Organizations root must run in the approved management account."
    }

    precondition {
      condition     = data.aws_organizations_organization.current.id == var.organization_id
      error_message = "The authenticated account belongs to a different AWS Organization than the approved contract."
    }
  }
}

resource "aws_organizations_organizational_unit" "platform" {
  for_each = var.organizational_units

  name      = each.value
  parent_id = data.aws_organizations_organization.current.roots[0].id
  tags      = merge(local.default_tags, { OrganizationalUnit = each.value })

  depends_on = [terraform_data.organization_contract]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy" "baseline" {
  for_each = local.policy_documents

  name        = "platform-${replace(each.key, "_", "-")}"
  description = "Direct Organizations baseline policy managed by the organization GitOps root."
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value
  tags        = merge(local.default_tags, { Policy = each.key })

  depends_on = [terraform_data.organization_contract]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "baseline" {
  for_each = {
    for pair in setproduct(keys(aws_organizations_organizational_unit.platform), keys(aws_organizations_policy.baseline)) :
    "${pair[0]}:${pair[1]}" => {
      ou_key     = pair[0]
      policy_key = pair[1]
    }
  }

  policy_id = aws_organizations_policy.baseline[each.value.policy_key].id
  target_id = aws_organizations_organizational_unit.platform[each.value.ou_key].id
}

resource "aws_organizations_account" "vended" {
  for_each = var.accounts

  name                       = each.value.name
  email                      = each.value.email
  parent_id                  = aws_organizations_organizational_unit.platform[each.value.parent_ou_key].id
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "ALLOW"
  close_on_deletion          = false
  tags                       = merge(local.default_tags, each.value.tags, { AccountKey = each.key })

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = contains(var.organizational_units, each.value.parent_ou_key)
      error_message = "Every vended account must reference a parent_ou_key present in organizational_units."
    }
  }
}
