output "transit_gateway" {
  description = "TGW identifiers passed to separately approved attachment, peering, and VPN composition."
  value       = module.transit_gateway_hub.transit_gateway
}

output "route_table_ids" {
  description = "ADR-defined route domain to route-table ID mapping."
  value       = module.transit_gateway_hub.route_table_ids
}

output "ram_resource_share_arn" {
  description = "RAM share ARN used by account-vending and attachment approval workflows."
  value       = module.transit_gateway_hub.ram_resource_share_arn
}

output "flow_logs" {
  description = "Encrypted TGW Flow Log and rejected-traffic alarm identifiers owned by the Network account."
  value       = module.transit_gateway_hub.flow_logs
}

output "network_routing" {
  description = "Accepted attachments and their Network-assigned domains. Null until the approved routing catalog is supplied."
  value       = try(module.network_routing["approved"], null)
}
