output "vpc" {
  description = "Private workload VPC contract for service and TGW attachment composition."
  value       = module.workload_regional.vpc
}

output "identity" {
  description = "Cognito primary contract or the explicit secondary MRR provider-support boundary."
  value = {
    primary_user_pool  = module.workload_regional.primary_user_pool
    replication_status = module.workload_regional.identity_replication_status
  }
}
