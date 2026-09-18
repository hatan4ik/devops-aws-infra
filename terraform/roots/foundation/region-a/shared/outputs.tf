output "state_backend" {
  description = "Non-secret backend values consumed by later roots through approved CI configuration, not Terraform remote-state reads."
  value       = module.state_backend.backend_configuration
}
