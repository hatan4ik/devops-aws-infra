# Sandbox network root

This root owns the isolated `10.64.0.0/16` development VPC, two private
subnets, private route tables, VPC Flow Logs, Flow Log KMS key, and restrictive
default security controls. It exposes no public subnets, NAT gateway, Internet
gateway route, transit gateway, VPN, or workload service.

Its inputs are deliberately small and reviewed: account, Region, CIDR, AZ-to-
subnet map, and Flow Log retention. Names and tags derive from the shared active
root context. GitHub Actions is the only supported apply path.

The workload root discovers this VPC and its private subnets through scoped AWS
data sources; it does not consume this root's Terraform state.
