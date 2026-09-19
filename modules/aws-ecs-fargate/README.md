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

- [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) (resource)
- [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) (resource)

## Required Inputs

The following input variables are required:

### <a name="input_config"></a> [config](#input\_config)

Description: Configuration for the ECS Fargate Cluster

Type:

```hcl
object({
    cluster_name              = string
    environment               = string
    enable_container_insights = optional(bool, true)
    tags                      = optional(map(string), {})
  })
```

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id)

Description: The ID of the ECS cluster

### <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name)

Description: The name of the ECS cluster
<!-- END_TF_DOCS -->
