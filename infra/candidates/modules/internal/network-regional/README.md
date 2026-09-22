# Internal network-regional composition module

Composes the independently released Transit Gateway hub into the Network account's regional root. Attachments, peering, VPN, BGP route filtering, and Resolver configuration remain separately owned changes because each requires cross-account or on-premises contract inputs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.35.0, < 7.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_transit_gateway_hub"></a> [transit\_gateway\_hub](#module\_transit\_gateway\_hub) | git::https://github.com/hatan4ik/aws.modules.tgw.git | v0.1.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_amazon_side_asn"></a> [amazon\_side\_asn](#input\_amazon\_side\_asn) | Approved private BGP ASN for the regional Transit Gateway. | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Lowercase name for this regional network hub. | `string` | n/a | yes |
| <a name="input_ram_principal_arns"></a> [ram\_principal\_arns](#input\_ram\_principal\_arns) | Approved AWS Organizations or account principals for the TGW RAM share. | `set(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Allocation and ownership tags passed unchanged to the TGW hub module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ram_resource_share_arn"></a> [ram\_resource\_share\_arn](#output\_ram\_resource\_share\_arn) | RAM share ARN used by account-vending and attachment approval workflows. |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | ADR-defined route domain to route-table ID mapping. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | TGW identifiers passed to separately approved attachment, peering, and VPN composition. |
<!-- END_TF_DOCS -->
