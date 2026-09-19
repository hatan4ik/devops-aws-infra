> Historical prototype only. This module is disabled by [ADR 0014](../../docs/adr/0014-canonical-architecture-and-iac-boundary.md) and must not be used as a deployment dependency.

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.7.0)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (>= 5.0.0, < 6.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws) (>= 5.0.0, < 6.0.0)

## Modules

No modules.

## Resources

The following resources are used by this module:

- [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) (resource)
- [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) (resource)

## Required Inputs

The following input variables are required:

### <a name="input_config"></a> [config](#input\_config)

Description: Configuration for CloudFront and ALB

Type:

```hcl
object({
    name                 = string
    environment          = string
    primary_alb_domain   = string
    secondary_alb_domain = optional(string, "")
    enable_waf           = optional(bool, true)
    tags                 = optional(map(string), {})
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_cloudfront_domain_name"></a> [cloudfront\_domain\_name](#output\_cloudfront\_domain\_name)

Description: The domain name of the CloudFront distribution

### <a name="output_cloudfront_hosted_zone_id"></a> [cloudfront\_hosted\_zone\_id](#output\_cloudfront\_hosted\_zone\_id)

Description: The Route 53 zone ID for the CloudFront distribution
<!-- END_TF_DOCS -->
