# Legacy state-backend adoption

This internal composition records the observed one-bucket bootstrap selected by
[ADR 0015](../../../../docs/adr/0015-adopt-legacy-state-bootstrap.md). It is
not a general state-backend module and must not be used for a new environment.
Use the [adoption runbook](../../../../docs/runbooks/adopt-legacy-state-backend.md)
to move existing state addresses only after an approved state-change record.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.35.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.65.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_dynamodb_table.state_lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_kms_alias.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_object_lock_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_s3_bucket_ownership_controls.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_public_access_block.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Observed, non-secret configuration of the legacy bootstrap state backend. Values must match the approved adoption inventory before state-address migration. | <pre>object({<br/>    bucket_name                          = string<br/>    dynamodb_table_name                  = string<br/>    kms_key_alias                        = string<br/>    kms_key_description                  = string<br/>    kms_key_deletion_window_in_days      = number<br/>    object_lock_retention_mode           = string<br/>    object_lock_retention_days           = number<br/>    dynamodb_deletion_protection_enabled = bool<br/>    tags                                 = map(string)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_identity"></a> [backend\_identity](#output\_backend\_identity) | Non-secret identifiers used only by the approved canonical state-migration runbook. |
<!-- END_TF_DOCS -->
