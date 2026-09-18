module "network_regional" {
  source = "../../../../modules/internal/network-regional"

  name               = var.network.name
  amazon_side_asn    = var.network.amazon_side_asn
  ram_principal_arns = var.network.ram_principal_arns
  tags               = local.default_tags
}
