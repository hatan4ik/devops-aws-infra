# Versioned Terraform module repositories

Reusable Terraform implementation lives in a dedicated GitHub repository. This
repository contains roots and composition only. Every Terraform `source` is a
Git URL pinned to an immutable release tag; never use a branch such as `main`.

| Capability | Repository | Current release | Current consumer |
|---|---|---|---|
| ACM certificates and DNS validation | [aws.modules.acm](https://github.com/hatan4ik/aws.modules.acm) | `v0.1.2` | Available for an approved domain/certificate root. |
| Cognito user pools and clients | [aws.modules.cognito](https://github.com/hatan4ik/aws.modules.cognito) | `v0.1.1` | Candidate workload composition and the ECS platform module. |
| ECS platform foundation | [aws.modules.ecs](https://github.com/hatan4ik/aws.modules.ecs) | `v0.1.0` | Active sandbox-platform root. |
| GitHub OIDC and delivery IAM | [aws.modules.iam](https://github.com/hatan4ik/aws.modules.iam) | `v0.1.1` | Active sandbox-delivery root. |
| Deterministic names and canonical tags | [aws.modules.naming](https://github.com/hatan4ik/aws.modules.naming) | `v0.1.0` | Active sandbox-network and sandbox-platform roots. |
| Customer-managed KMS keys | [aws.modules.ksm](https://github.com/hatan4ik/aws.modules.ksm) | `v0.1.2` | Available for new approved service roots. The repository name is intentionally preserved as supplied. |
| Route 53 zones and records | [aws.modules.route53](https://github.com/hatan4ik/aws.modules.route53) | `v0.1.2` | Available for an approved DNS root. |
| Private encrypted S3 buckets | [aws.modules.s3](https://github.com/hatan4ik/aws.modules.s3) | `v0.1.2` | Available for new approved data roots. |
| Terraform state backends and adoption | [aws.modules.state](https://github.com/hatan4ik/aws.modules.state) | `v0.1.0` | Candidate foundation and controlled legacy-adoption roots. |
| Transit Gateway hub and VPC attachment | [aws.modules.tgw](https://github.com/hatan4ik/aws.modules.tgw) | `v0.1.1` | Candidate regional-network composition. |
| VPC foundations and workload VPCs | [aws.modules.vpc](https://github.com/hatan4ik/aws.modules.vpc) | `v0.1.1` | Active sandbox-network root and candidate workload composition. |
| Encrypted DynamoDB tables | [aws.modules.dynamodb](https://github.com/hatan4ik/aws.modules.dynamodb) | `v0.1.2` | Available for new approved state or workload roots. |

## Consumer rule

Use the exact tag released by the upstream module. Examples:

```hcl
module "network" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git?ref=v0.1.1"
}

module "workload_vpc" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git//modules/workload?ref=v0.1.1"
}
```

An upstream change does nothing until a reviewed pull request updates the tag
in the consuming root. That review is the upgrade boundary and preserves a
reproducible Terraform plan.

The naming module derives deterministic names and canonical tags from reviewed
static context. It does not discover account IDs, backend coordinates, or OIDC
trust values: those are explicit root security and bootstrap contracts.

## Deliberate boundaries

- `archive/prototypes/` is historical evidence and is not republished.
- ACM and Route 53 have no current consumer because DNS/certificate ownership
  and the public-ingress ADR gate are unresolved.
- The state module is separate because its multi-Region replication, Object
  Lock, and recovery policy require a stronger contract than a generic S3,
  KMS, or DynamoDB resource wrapper.
