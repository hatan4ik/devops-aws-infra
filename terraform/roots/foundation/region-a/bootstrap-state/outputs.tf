output "legacy_state_backend" {
  description = "Non-secret identity of the adopted bootstrap state backend."
  value       = module.legacy_state_backend.backend_identity
}
