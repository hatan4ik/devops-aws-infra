output "delegated_ipam_admin" {
  description = "Delegated Network account for the follow-on IPAM home-Region root."
  value       = module.ipam_organization_admin.delegated_admin
}
