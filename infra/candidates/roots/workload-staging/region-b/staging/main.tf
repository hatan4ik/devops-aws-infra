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
        var.aws_region == var.regional_region_registry["secondary"]
      )
      error_message = "The region-b workload root must use the secondary Region in a reviewed, distinct primary/secondary regional_region_registry."
    }
  }
}

module "workload_regional" {
  source = "../../../../modules/internal/workload-regional"

  workload_name              = var.workload.name
  vpc                        = var.workload.vpc
  transit_gateway_attachment = var.workload.transit_gateway_attachment
  identity                   = var.workload.identity
  tags                       = local.default_tags

  depends_on = [terraform_data.regional_region_policy]
}
