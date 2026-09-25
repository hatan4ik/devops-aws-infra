# State moves for the aws.modules.cognito v1 + aws.modules.ecs v1 migration.
#
# Two content-only (non-address) changes are expected alongside these pure
# moves, both safe in-place policy-document updates, not replacements:
#   - the shared KMS key policy's CloudWatch Logs statement Sid changes from
#     "AllowCloudWatchLogsForApplicationLogGroup" to
#     "AllowCloudWatchLogsForApplicationLogGroups" (v1's wording)
#   - the ECR lifecycle policy's rule description changes from "Retain the
#     newest 30 immutable application images." to "Retain the newest 30
#     images." (v1's wording); the rule's actual behavior (imageCountMoreThan
#     30, tagStatus any, expire) is unchanged
#
# module.sandbox_platform_core.module.cognito.terraform_data.mrr_provider_capability
# has no moved block and is expected to show as a destroy: it was a
# Terraform-only guard resource with no AWS side effect (v1 removed the
# always-rejecting replication input it guarded), so destroying it changes
# nothing in the real account.

moved {
  from = module.sandbox_platform_core.module.cognito.aws_cognito_user_pool.this
  to   = module.cognito.aws_cognito_user_pool.this
}

moved {
  from = module.sandbox_platform_core.aws_ecs_cluster.application
  to   = module.sandbox_platform_core.aws_ecs_cluster.this
}

moved {
  from = module.sandbox_platform_core.aws_security_group.interface_endpoints
  to   = module.sandbox_platform_core.module.endpoints.aws_security_group.this[0]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_security_group_ingress_rule.interface_endpoints_tls
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_security_group_ingress_rule.https["0"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.interface["cognito-idp"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.interface["cognito-idp"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.interface["ecr.api"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.interface["ecr.api"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.interface["ecr.dkr"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.interface["ecr.dkr"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.interface["logs"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.interface["logs"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.interface["secretsmanager"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.interface["secretsmanager"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.interface["ssm"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.interface["ssm"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.interface["ssmmessages"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.interface["ssmmessages"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.interface["sts"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.interface["sts"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.gateway["dynamodb"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.gateway["dynamodb"]
}

moved {
  from = module.sandbox_platform_core.aws_vpc_endpoint.gateway["s3"]
  to   = module.sandbox_platform_core.module.endpoints.aws_vpc_endpoint.gateway["s3"]
}

moved {
  from = module.sandbox_platform_core.aws_ecr_repository.application
  to   = module.sandbox_platform_core.module.registry[0].aws_ecr_repository.this
}

moved {
  from = module.sandbox_platform_core.aws_ecr_lifecycle_policy.application
  to   = module.sandbox_platform_core.module.registry[0].aws_ecr_lifecycle_policy.this[0]
}

moved {
  from = module.sandbox_platform_core.aws_dynamodb_table.session
  to   = module.sandbox_platform_core.module.session_store[0].aws_dynamodb_table.this
}
