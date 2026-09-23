# Internal network-regional composition module

Composes the independently released Transit Gateway hub into the Network account's regional root. Attachments, peering, VPN, BGP route filtering, and Resolver configuration remain separately owned changes because each requires cross-account or on-premises contract inputs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.35.0, < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_network_routing"></a> [network\_routing](#module\_network\_routing) | git::https://github.com/hatan4ik/aws.modules.tgw.git//modules/network-routing | 886043384c3bc1637ed9b64e72d2af87d172d52e |
| <a name="module_transit_gateway_hub"></a> [transit\_gateway\_hub](#module\_transit\_gateway\_hub) | git::https://github.com/hatan4ik/aws.modules.tgw.git | 886043384c3bc1637ed9b64e72d2af87d172d52e |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.route_policy](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_amazon_side_asn"></a> [amazon\_side\_asn](#input\_amazon\_side\_asn) | Approved private BGP ASN for the regional Transit Gateway. | `number` | n/a | yes |
| <a name="input_flow_log_retention_in_days"></a> [flow\_log\_retention\_in\_days](#input\_flow\_log\_retention\_in\_days) | Retention period for encrypted TGW Flow Logs. The network baseline is at least one year. | `number` | `365` | no |
| <a name="input_name"></a> [name](#input\_name) | Lowercase name for this regional network hub. | `string` | n/a | yes |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | Approved 12-digit AWS account IDs or AWS Organizations organization/OU ARNs for the TGW RAM share. IAM principals are deliberately invalid. | `set(string)` | `[]` | no |
| <a name="input_rejected_traffic_alarm_actions"></a> [rejected\_traffic\_alarm\_actions](#input\_rejected\_traffic\_alarm\_actions) | Optional SNS or incident-management action ARNs for rejected TGW traffic. | `set(string)` | `[]` | no |
| <a name="input_rejected_traffic_alarm_threshold"></a> [rejected\_traffic\_alarm\_threshold](#input\_rejected\_traffic\_alarm\_threshold) | Rejected TGW flow-log records in five minutes that trigger the network alarm. | `number` | `1` | no |
| <a name="input_route_domains"></a> [route\_domains](#input\_route\_domains) | Network-owned TGW route domains. The default keeps production, non-production, shared, inspection, and on-premises routing separate. | `set(string)` | <pre>[<br/>  "prod",<br/>  "non-prod",<br/>  "shared",<br/>  "inspection",<br/>  "on-prem"<br/>]</pre> | no |
| <a name="input_routing"></a> [routing](#input\_routing) | Network-account-owned attachment catalog and explicit propagation/static-route policy. Null creates the hub only; a workload account never supplies this value. | <pre>object({<br/>    approved_account_domains = map(string)<br/>    attachments = map(object({<br/>      attachment_id = string<br/>      account_id    = string<br/>    }))<br/>    propagation_matrix = map(set(string))<br/>    static_routes = optional(map(object({<br/>      route_table_domain     = string<br/>      destination_cidr_block = string<br/>      blackhole              = bool<br/>      target_attachment_key  = optional(string)<br/>    })), {})<br/>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Allocation and ownership tags passed unchanged to the TGW hub module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_flow_logs"></a> [flow\_logs](#output\_flow\_logs) | Encrypted TGW Flow Log and rejected-traffic alarm identifiers owned by the Network account. |
| <a name="output_network_routing"></a> [network\_routing](#output\_network\_routing) | Accepted attachments and their Network-assigned domains. Null until the approved routing catalog is supplied. |
| <a name="output_ram_resource_share_arn"></a> [ram\_resource\_share\_arn](#output\_ram\_resource\_share\_arn) | RAM share ARN used by account-vending and attachment approval workflows. |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | ADR-defined route domain to route-table ID mapping. |
| <a name="output_transit_gateway"></a> [transit\_gateway](#output\_transit\_gateway) | TGW identifiers passed to separately approved attachment, peering, and VPN composition. |
<!-- END_TF_DOCS -->
