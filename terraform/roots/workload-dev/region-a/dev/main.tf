module "workload_regional" {
  source = "../../../../modules/internal/workload-regional"

  workload_name = var.workload.name
  vpc           = var.workload.vpc
  identity      = var.workload.identity
  tags          = local.default_tags
}
