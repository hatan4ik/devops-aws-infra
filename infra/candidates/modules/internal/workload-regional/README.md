# Internal workload-regional composition module

Composes the private workload VPC and, in the primary Region only, the secure Cognito primary user pool. A secondary root creates no independent pool: Cognito MRR is an explicit provider-support blocker under ADR 0011.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.35.0, < 7.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cognito_primary"></a> [cognito\_primary](#module\_cognito\_primary) | git::https://github.com/hatan4ik/aws.modules.cognito.git | 5d605eff1d5cdabf84b6f525ed56e0057b84152d |
| <a name="module_transit_gateway_attachment"></a> [transit\_gateway\_attachment](#module\_transit\_gateway\_attachment) | git::https://github.com/hatan4ik/aws.modules.tgw.git//modules/vpc-attachment | 886043384c3bc1637ed9b64e72d2af87d172d52e |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | git::https://github.com/hatan4ik/aws.modules.vpc.git//modules/workload | ada254e7327ff9f401df41c0819a34fc7891938f |

## Resources

| Name | Type |
|------|------|
| [terraform_data.transit_gateway_contract](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_identity"></a> [identity](#input\_identity) | Primary creates the secure Cognito pool; secondary deliberately creates no independent pool while MRR is provider-blocked. | <pre>object({<br/>    mode = string<br/>    user_pool = optional(object({<br/>      name                = string<br/>      feature_plan        = string<br/>      deletion_protection = bool<br/>      mfa_configuration   = string<br/>      password_policy = object({<br/>        minimum_length                   = number<br/>        temporary_password_validity_days = number<br/>      })<br/>      clients = map(object({<br/>        callback_urls          = set(string)<br/>        logout_urls            = set(string)<br/>        allowed_oauth_scopes   = set(string)<br/>        access_token_validity  = number<br/>        id_token_validity      = number<br/>        refresh_token_validity = number<br/>        generate_secret        = bool<br/>      }))<br/>      resource_servers = map(object({<br/>        identifier = string<br/>        name       = string<br/>        scopes = map(object({<br/>          description = string<br/>        }))<br/>      }))<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Allocation and ownership tags passed to the regional component modules. | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_attachment"></a> [transit\_gateway\_attachment](#input\_transit\_gateway\_attachment) | Optional workload-side TGW attachment request. The attachment\_key is an opaque Network-account catalog key, not a route domain. | <pre>object({<br/>    transit_gateway_id     = string<br/>    attachment_key         = string<br/>    appliance_mode_support = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Typed private VPC, endpoint, and Flow Log configuration. | <pre>object({<br/>    ipv4_ipam_pool_id   = string<br/>    ipv4_netmask_length = number<br/>    availability_zones = map(object({<br/>      availability_zone = string<br/>      subnet_newbits    = number<br/>      subnet_netnum     = number<br/>    }))<br/>    transit_gateway_attachment_subnets = optional(map(object({<br/>      subnet_newbits = number<br/>      subnet_netnum  = number<br/>    })), {})<br/>    transit_gateway_routes = optional(map(object({<br/>      destination_cidr_block = string<br/>      transit_gateway_id     = string<br/>    })), {})<br/>    interface_endpoints = map(object({<br/>      service_name        = string<br/>      private_dns_enabled = bool<br/>      policy_json         = optional(string)<br/>    }))<br/>    gateway_endpoints = map(object({<br/>      service_name = string<br/>      policy_json  = optional(string)<br/>    }))<br/>    flow_log_kms_key_arn       = string<br/>    flow_log_retention_in_days = number<br/>  })</pre> | n/a | yes |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | Lowercase workload and environment name passed to regional component modules. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_identity_replication_status"></a> [identity\_replication\_status](#output\_identity\_replication\_status) | Explicit MRR readiness state; a secondary VPC is not evidence of Cognito replica deployment. |
| <a name="output_primary_user_pool"></a> [primary\_user\_pool](#output\_primary\_user\_pool) | Primary user-pool contract when this is the primary Region; null for a secondary Region. |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | Stable private subnet contract for private application services and TGW attachment composition. |
| <a name="output_transit_gateway_attachment"></a> [transit\_gateway\_attachment](#output\_transit\_gateway\_attachment) | Workload-created TGW attachment sent to the Network account for separate acceptance and route-domain assignment. |
| <a name="output_transit_gateway_attachment_subnets"></a> [transit\_gateway\_attachment\_subnets](#output\_transit\_gateway\_attachment\_subnets) | Dedicated transit-subnet contract used exclusively for the workload-side TGW attachment. |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | Private VPC contract for workload compute and the separately approved TGW attachment. |
<!-- END_TF_DOCS -->
