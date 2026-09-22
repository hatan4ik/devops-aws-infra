output "services" {
  description = "Non-secret private Fargate service identifiers by application key."
  value       = module.sandbox_workload.services
}
