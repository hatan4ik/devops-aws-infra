# Versioned Terraform modules

Reusable Terraform is maintained in its owning `aws.modules.*` repository.
This GitOps repository contains root composition only; it never copies module
implementation into `infra/active`.

| Capability | Repository | Release used or available |
|---|---|---|
| Private Fargate services | [aws.modules.ecs-service](https://github.com/hatan4ik/aws.modules.ecs-service) | Active workload root uses `v0.1.4`. The v1 design requires a signed release and a state-move migration. |
| ECS platform foundation | [aws.modules.ecs](https://github.com/hatan4ik/aws.modules.ecs) | `v0.1.2` in the active sandbox-platform root. |
| GitHub OIDC and delivery IAM | [aws.modules.iam](https://github.com/hatan4ik/aws.modules.iam) | `v0.1.10` in the active sandbox-delivery root. |
| VPC foundations | [aws.modules.vpc](https://github.com/hatan4ik/aws.modules.vpc) | `v1.0.0` is pinned by the active sandbox-network migration PR. |
| Deterministic names and tags | [aws.modules.naming](https://github.com/hatan4ik/aws.modules.naming) | `v0.1.0` in active sandbox roots. |
| Cognito | [aws.modules.cognito](https://github.com/hatan4ik/aws.modules.cognito) | `v0.1.1`, consumed by the platform foundation. |
| Supporting services | [ACM](https://github.com/hatan4ik/aws.modules.acm), [KMS](https://github.com/hatan4ik/aws.modules.ksm), [Route 53](https://github.com/hatan4ik/aws.modules.route53), [S3](https://github.com/hatan4ik/aws.modules.s3), [DynamoDB](https://github.com/hatan4ik/aws.modules.dynamodb), [TGW](https://github.com/hatan4ik/aws.modules.tgw), and [state](https://github.com/hatan4ik/aws.modules.state) | Available for a separately approved root. |

## Consumer rule

Every root pins the full 40-character commit SHA resolved from an annotated
semantic-version release tag. The tag is retained as an inline comment for
reviewers; verify its signature when the release authority has signing
material available.

```hcl
module "network" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git?ref=ada254e7327ff9f401df41c0819a34fc7891938f" # v0.3.0
}
```

Never follow `main`, a mutable tag, a local checkout, or a relative module
path. A module upgrade is a root pull request: its plan is the compatibility
proof, and its rollback is a revert to the previous immutable commit.
