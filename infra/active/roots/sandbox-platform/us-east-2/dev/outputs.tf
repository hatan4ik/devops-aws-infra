output "private_endpoints" {
  description = "Private endpoint IDs available to future ECS workloads."
  value       = module.sandbox_platform_core.private_endpoints
}

output "application" {
  description = "Non-secret application platform identifiers."
  value       = module.sandbox_platform_core.application
}

output "user_pool" {
  description = "Primary user-pool identifiers required by application token validation."
  value       = module.cognito.user_pool
}
