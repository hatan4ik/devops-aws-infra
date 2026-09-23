module "ipam_organization_admin" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git//modules/ipam-organization-admin?ref=ada254e7327ff9f401df41c0819a34fc7891938f" # v0.3.0

  delegated_admin_account_id = var.delegated_ipam_admin_account_id
  tags                       = local.default_tags

  depends_on = [terraform_data.regional_region_policy]
}

resource "terraform_data" "regional_region_policy" {
  input = {
    aws_region               = var.aws_region
    regional_region_registry = var.regional_region_registry
  }

  lifecycle {
    precondition {
      condition = (
        can(var.regional_region_registry["primary"]) &&
        can(var.regional_region_registry["secondary"]) &&
        var.regional_region_registry["primary"] != var.regional_region_registry["secondary"] &&
        var.aws_region == var.regional_region_registry["primary"]
      )
      error_message = "The IPAM organization-admin root must use the primary Region in a reviewed, distinct primary/secondary regional_region_registry."
    }
  }
}
