module "transit_gateway_hub" {
  source = "../../terraform-aws-tgw-hub"

  name               = var.name
  amazon_side_asn    = var.amazon_side_asn
  ram_principal_arns = var.ram_principal_arns
  tags               = var.tags
}
