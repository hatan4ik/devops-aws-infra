# Versioned Terraform modules

Reusable Terraform is maintained in its owning `aws.modules.*` repository.
This GitOps repository contains root composition only; it never copies module
implementation into `infra/active`.

| Capability | Repository | Consumption status |
|---|---|---|
| Private Fargate services | [aws.modules.ecs-service](https://github.com/hatan4ik/aws.modules.ecs-service) | Active workload root pins `v0.1.4`; the v1 design still needs a signed release and reviewed state migration. |
| ECS platform foundation | [aws.modules.ecs](https://github.com/hatan4ik/aws.modules.ecs) | Active sandbox-platform root pins `v0.1.2`. |
| GitHub OIDC and delivery IAM | [aws.modules.iam](https://github.com/hatan4ik/aws.modules.iam) | Active sandbox-delivery root pins `v0.1.13`. |
| VPC foundations | [aws.modules.vpc](https://github.com/hatan4ik/aws.modules.vpc) | Active sandbox-network root pins `v1.0.0`. |
| Deterministic names and tags | [aws.modules.naming](https://github.com/hatan4ik/aws.modules.naming) | Active sandbox roots pin `v0.1.0`. |
| Cognito primary pool and native MRR adoption | [aws.modules.cognito](https://github.com/hatan4ik/aws.modules.cognito) | Primary pool `v0.1.1` is consumed by the platform foundation. The AWSCC MRR submodule is merged but has no signed release or active-root consumer; see ADR 0024. |
| Network hub and three-phase spoke routing | [aws.modules.tgw](https://github.com/hatan4ik/aws.modules.tgw) | Attachment request, network routing receipt, and spoke-route activation barrier are implemented; no Network root consumes them yet. |
| Static web edge composition | [aws.modules.blueprint-edge-web-app](https://github.com/hatan4ik/aws.modules.blueprint-edge-web-app) | Secure S3/CloudFront/ACM/WAF/KMS/Route 53 baseline is published; no signed release or active-root consumer yet. |
| Private microservice composition | [aws.modules.blueprint-microservice-private](https://github.com/hatan4ik/aws.modules.blueprint-microservice-private) | VPC/ALB/ECS-service golden path is available; no active root consumes it. |
| Edge and ingress leaves | [ACM](https://github.com/hatan4ik/aws.modules.acm), [CloudFront](https://github.com/hatan4ik/aws.modules.cloudfront), [WAF](https://github.com/hatan4ik/aws.modules.waf), [Route 53](https://github.com/hatan4ik/aws.modules.route53), [ALB](https://github.com/hatan4ik/aws.modules.alb), [Global Accelerator](https://github.com/hatan4ik/aws.modules.global-accelerator), and [security group](https://github.com/hatan4ik/aws.modules.security-group) | Independently tested leaves; consume only through an approved root or blueprint release. |
| Data, encryption, and state leaves | [KMS](https://github.com/hatan4ik/aws.modules.kms), [S3](https://github.com/hatan4ik/aws.modules.s3), [DynamoDB](https://github.com/hatan4ik/aws.modules.dynamodb), and [state](https://github.com/hatan4ik/aws.modules.state) | Independently tested leaves; consume only through an approved immutable pin. `aws.modules.kms` is the canonical repository name; `aws.modules.ksm` is obsolete. |
| Legacy CloudFormation wrapper | [aws.modules.cloudformation](https://github.com/hatan4ik/aws.modules.cloudformation) | Not approved for new Cognito MRR ownership after ADR 0024. Confirm all consumers are absent before separately archiving the repository. |

## Consumer rule

Every root pins the full 40-character commit SHA resolved from an annotated
semantic-version release tag. The tag is retained as an inline comment for
reviewers; verify its signature when the release authority has signing
material available.

```hcl
module "network" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git?ref=5c0092737c51c99c699bb7122ea147c65b9ca507" # v1.0.0
}
```

Never follow `main`, a mutable tag, a local checkout, or a relative module
path. A module upgrade is a root pull request: its plan is the compatibility
proof, and its rollback is a revert to the previous immutable commit.
