output "ipam" {
  description = "Network-account IPAM contract for a reviewed workload-root tfvars update."
  value       = module.ipam.ipam
}

output "regional_pools" {
  description = "Regional pool IDs and RAM-share evidence. Do not wire these through a remote-state data source; promote reviewed output values into root configuration."
  value       = module.ipam.regional_pools
}
