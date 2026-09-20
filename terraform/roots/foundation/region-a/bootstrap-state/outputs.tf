output "legacy_state_backend" {
  description = "Non-secret identity of the adopted bootstrap state backend."
  value       = module.legacy_state_backend.backend_identity
}

output "backend_configuration" {
  description = "Compatibility-shaped backend configuration for the transitional legacy tier."
  value       = module.legacy_state_backend.backend_configuration
}

output "state_access_policy_arns" {
  description = "Compatibility-shaped least-privilege policy identifiers for the transitional legacy tier."
  value       = module.legacy_state_backend.state_access_policy_arns
}
