output "vpc" {
  description = "Private VPC contract for workload compute and the separately approved TGW attachment."
  value       = module.vpc.vpc
}

output "private_subnets" {
  description = "Stable private subnet contract for private application services and TGW attachment composition."
  value       = module.vpc.private_subnets
}

output "primary_user_pool" {
  description = "Primary user-pool contract when this is the primary Region; null for a secondary Region."
  value       = try(module.cognito_primary["primary"].user_pool, null)
}

output "identity_replication_status" {
  description = "Explicit MRR readiness state; a secondary VPC is not evidence of Cognito replica deployment."
  value = var.identity.mode == "primary" ? module.cognito_primary["primary"].replication_status : {
    managed_by_terraform = false
    status               = "blocked-provider-support"
  }
}
