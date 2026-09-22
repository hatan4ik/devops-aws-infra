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

- [aws_cognito_user_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) (resource)
- [aws_cognito_user_pool_client.client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) (resource)
- [aws_cognito_user_pool_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) (resource)

## Required Inputs

The following input variables are required:

### <a name="input_config"></a> [config](#input\_config)

Description: Configuration for the Cognito User Pool

Type:

```hcl
object({
    pool_name               = string
    environment             = string
    domain_prefix           = string
    callback_urls           = list(string)
    logout_urls             = list(string)
    advanced_security_mode  = optional(string, "ENFORCED")
    enable_mfa              = optional(string, "ON")
    minimum_password_length = optional(number, 14)
    tags                    = optional(map(string), {})
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_user_pool_client_id"></a> [user\_pool\_client\_id](#output\_user\_pool\_client\_id)

Description: The ID of the Cognito User Pool Client

### <a name="output_user_pool_domain"></a> [user\_pool\_domain](#output\_user\_pool\_domain)

Description: The domain of the Cognito User Pool

### <a name="output_user_pool_id"></a> [user\_pool\_id](#output\_user\_pool\_id)

Description: The ID of the Cognito User Pool
<!-- END_TF_DOCS -->
