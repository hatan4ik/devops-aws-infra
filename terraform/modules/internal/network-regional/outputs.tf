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
