output "transit_gateway" {
  description = "Regional TGW contract for separately approved attachment, peering, VPN, and route composition."
  value       = module.network_regional.transit_gateway
}

output "route_table_ids" {
  description = "Fixed route domain to TGW route-table ID mapping."
  value       = module.network_regional.route_table_ids
}
