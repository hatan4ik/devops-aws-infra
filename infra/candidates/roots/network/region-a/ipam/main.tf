module "ipam" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git//modules/ipam?ref=ada254e7327ff9f401df41c0819a34fc7891938f" # v0.3.0

  name              = var.ipam.name
  home_region       = var.aws_region
  operating_regions = var.ipam.operating_regions
  top_level_cidr    = var.ipam.top_level_cidr
  regional_pools    = var.ipam.regional_pools
  tags              = local.default_tags

  depends_on = [terraform_data.regional_region_policy]
}

resource "terraform_data" "regional_region_policy" {
  input = {
    aws_region               = var.aws_region
    regional_region_registry = var.regional_region_registry
    operating_regions        = var.ipam.operating_regions
  }

  lifecycle {
    precondition {
      condition = (
        can(var.regional_region_registry["primary"]) &&
        can(var.regional_region_registry["secondary"]) &&
        var.regional_region_registry["primary"] != var.regional_region_registry["secondary"] &&
        var.aws_region == var.regional_region_registry["primary"]
      )
      error_message = "The IPAM home-Region root must use the primary Region in a reviewed, distinct primary/secondary regional_region_registry."
    }

    precondition {
      condition = (
        contains(var.ipam.operating_regions, var.regional_region_registry["primary"]) &&
        contains(var.ipam.operating_regions, var.regional_region_registry["secondary"])
      )
      error_message = "ipam.operating_regions must include both reviewed primary and secondary Regions."
    }
  }
}
