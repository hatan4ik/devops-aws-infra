> Historical prototype only. This module is disabled by [ADR 0014](../../docs/adr/0014-canonical-architecture-and-iac-boundary.md) and must not be used as a deployment dependency.

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9.0)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (>= 5.0.0, < 6.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws) (>= 5.0.0, < 6.0.0)

- <a name="provider_random"></a> [random](#provider\_random)

## Modules

No modules.

## Resources

The following resources are used by this module:

- [aws_dynamodb_table.lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) (resource)
- [aws_kms_alias.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) (resource)
- [aws_kms_key.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) (resource)
- [aws_s3_bucket.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) (resource)
- [aws_s3_bucket_object_lock_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) (resource)
- [aws_s3_bucket_public_access_block.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) (resource)
- [aws_s3_bucket_server_side_encryption_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) (resource)
- [aws_s3_bucket_versioning.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) (resource)
- [random_id.bucket_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

## Required Inputs

The following input variables are required:

### <a name="input_config"></a> [config](#input\_config)

Description: Configuration object for the Terraform state backend.

Type:

```hcl
object({
    bucket_prefix = string
    table_name    = string
    kms_key_alias = optional(string, "alias/terraform-state-backend")
    environment   = string
    tags          = optional(map(string), {})
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_dynamodb_table_name"></a> [dynamodb\_table\_name](#output\_dynamodb\_table\_name)

Description: The name of the DynamoDB table used for state locking.

### <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn)

Description: The ARN of the KMS key used for encrypting the state bucket and lock table.

### <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn)

Description: The ARN of the S3 bucket used for state storage.

### <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id)

Description: The ID of the S3 bucket used for state storage.
<!-- END_TF_DOCS -->
