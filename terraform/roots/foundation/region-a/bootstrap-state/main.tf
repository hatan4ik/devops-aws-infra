module "legacy_state_backend" {
  source = "../../../../modules/internal/legacy-state-backend-adoption"

  config = var.legacy_state_backend
}
