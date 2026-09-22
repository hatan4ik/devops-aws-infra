module "transit_gateway_hub" {
  source = "git::https://github.com/hatan4ik/aws.modules.tgw.git?ref=v0.1.1"

  name               = var.name
  amazon_side_asn    = var.amazon_side_asn
  ram_principal_arns = var.ram_principal_arns
  tags               = var.tags
}
