output "vpc" {
  description = "Isolated sandbox VPC contract for a later approved TGW attachment."
  value       = module.sandbox_network.vpc
}

output "private_subnets" {
  description = "Private-only subnet contract. No route to public internet is created."
  value       = module.sandbox_network.private_subnets
}

output "flow_logs" {
  description = "VPC Flow Logs destination and delivery role."
  value       = module.sandbox_network.flow_logs
}
