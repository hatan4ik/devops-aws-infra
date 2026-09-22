output "services" {
  description = "Non-secret private Fargate service identifiers by application key."
  value       = module.sandbox_workload.services
}

output "cluster_name" {
  description = "Existing ECS cluster that hosts the private workload services."
  value       = data.aws_ecs_cluster.platform.cluster_name
}
