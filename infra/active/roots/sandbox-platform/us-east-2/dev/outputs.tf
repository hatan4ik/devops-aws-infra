output "private_endpoints" {
  description = "Private endpoint IDs available to future ECS workloads."
  value       = module.sandbox_platform_core.private_endpoints
}

output "application" {
  description = "Non-secret application platform identifiers."
  value       = module.sandbox_platform_core.application
}
