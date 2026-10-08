# Versioned Terraform modules

Reusable Terraform is maintained in its owning `aws.modules.*` repository.
This GitOps repository contains root composition only; it never copies module
implementation into `infra/active`.

| Capability | Repository | Current signed release | Consumption status |
|---|---|---|---|
| TLS certificates | [aws.modules.acm](https://github.com/hatan4ik/aws.modules.acm) | [`v1.1.0`](https://github.com/hatan4ik/aws.modules.acm/releases/tag/v1.1.0) | Released leaf; no active root consumer. |
| Application load balancers | [aws.modules.alb](https://github.com/hatan4ik/aws.modules.alb) | [`v1.1.0`](https://github.com/hatan4ik/aws.modules.alb/releases/tag/v1.1.0) | Released leaf and blueprint dependency; no direct active-root consumer. |
| Static web edge composition | [aws.modules.blueprint-edge-web-app](https://github.com/hatan4ik/aws.modules.blueprint-edge-web-app) | [`v1.0.1`](https://github.com/hatan4ik/aws.modules.blueprint-edge-web-app/releases/tag/v1.0.1) | Released S3/CloudFront/ACM/WAF/KMS/Route 53 golden path; no active-root consumer. |
| Private microservice composition | [aws.modules.blueprint-microservice-private](https://github.com/hatan4ik/aws.modules.blueprint-microservice-private) | [`v1.0.2`](https://github.com/hatan4ik/aws.modules.blueprint-microservice-private/releases/tag/v1.0.2) | Released VPC/ALB/ECS-service golden path; no active-root consumer. |
| Legacy CloudFormation wrapper | [aws.modules.cloudformation](https://github.com/hatan4ik/aws.modules.cloudformation) | [`v1.0.4`](https://github.com/hatan4ik/aws.modules.cloudformation/releases/tag/v1.0.4) | Not approved for new Cognito MRR ownership after ADR 0024. Confirm all consumers are absent before separately archiving the repository. |
| CloudFront distributions | [aws.modules.cloudfront](https://github.com/hatan4ik/aws.modules.cloudfront) | [`v2.0.0`](https://github.com/hatan4ik/aws.modules.cloudfront/releases/tag/v2.0.0) | Released edge leaf and blueprint dependency; no direct active-root consumer. |
| Cognito pools and native MRR adoption | [aws.modules.cognito](https://github.com/hatan4ik/aws.modules.cognito) | [`v2.0.0`](https://github.com/hatan4ik/aws.modules.cognito/releases/tag/v2.0.0) | MRR support is released; the active platform remains on its reviewed v0.x identity path and needs a separate migration plan. |
| DynamoDB tables | [aws.modules.dynamodb](https://github.com/hatan4ik/aws.modules.dynamodb) | [`v1.0.1`](https://github.com/hatan4ik/aws.modules.dynamodb/releases/tag/v1.0.1) | Released data leaf; no direct active-root consumer. |
| ECS platform foundation | [aws.modules.ecs](https://github.com/hatan4ik/aws.modules.ecs) | [`v1.0.1`](https://github.com/hatan4ik/aws.modules.ecs/releases/tag/v1.0.1) | Active sandbox-platform root remains pinned to `v0.1.2`; upgrade requires a reviewed plan and state migration. |
| Private Fargate services | [aws.modules.ecs-service](https://github.com/hatan4ik/aws.modules.ecs-service) | [`v1.0.2`](https://github.com/hatan4ik/aws.modules.ecs-service/releases/tag/v1.0.2) | Active workload root remains pinned to `v0.1.4`; upgrade requires a reviewed plan and state migration. |
| Global Accelerator | [aws.modules.global-accelerator](https://github.com/hatan4ik/aws.modules.global-accelerator) | [`v2.0.0`](https://github.com/hatan4ik/aws.modules.global-accelerator/releases/tag/v2.0.0) | Released edge leaf; no active-root consumer. |
| GitHub OIDC and delivery IAM | [aws.modules.iam](https://github.com/hatan4ik/aws.modules.iam) | [`v1.0.1`](https://github.com/hatan4ik/aws.modules.iam/releases/tag/v1.0.1) | Active sandbox-delivery root remains pinned to `v0.1.13`; upgrade requires a reviewed plan. |
| KMS keys and policies | [aws.modules.kms](https://github.com/hatan4ik/aws.modules.kms) | [`v2.0.0`](https://github.com/hatan4ik/aws.modules.kms/releases/tag/v2.0.0) | Released encryption leaf and blueprint dependency. `aws.modules.ksm` is obsolete. |
| Deterministic names and tags | [aws.modules.naming](https://github.com/hatan4ik/aws.modules.naming) | [`v1.0.1`](https://github.com/hatan4ik/aws.modules.naming/releases/tag/v1.0.1) | Active sandbox roots remain pinned to `v0.1.0`; upgrade requires a reviewed plan. |
| Resource Groups queries | [aws.modules.resource-groups](https://github.com/hatan4ik/aws.modules.resource-groups) | [`v1.0.2`](https://github.com/hatan4ik/aws.modules.resource-groups/releases/tag/v1.0.2) | Released operational leaf; no active-root consumer. |
| Route 53 zones and records | [aws.modules.route53](https://github.com/hatan4ik/aws.modules.route53) | [`v1.0.1`](https://github.com/hatan4ik/aws.modules.route53/releases/tag/v1.0.1) | Released DNS leaf and blueprint dependency; no direct active-root consumer. |
| S3 buckets | [aws.modules.s3](https://github.com/hatan4ik/aws.modules.s3) | [`v1.0.2`](https://github.com/hatan4ik/aws.modules.s3/releases/tag/v1.0.2) | Released storage leaf and blueprint dependency; no direct active-root consumer. |
| Security groups | [aws.modules.security-group](https://github.com/hatan4ik/aws.modules.security-group) | [`v1.2.1`](https://github.com/hatan4ik/aws.modules.security-group/releases/tag/v1.2.1) | Released network-security leaf and transitive dependency. |
| Terraform state foundations | [aws.modules.state](https://github.com/hatan4ik/aws.modules.state) | [`v1.0.1`](https://github.com/hatan4ik/aws.modules.state/releases/tag/v1.0.1) | Released state leaf; existing backend adoption remains governed by its dedicated runbook and state. |
| Network hub and three-phase spoke routing | [aws.modules.tgw](https://github.com/hatan4ik/aws.modules.tgw) | [`v1.1.0`](https://github.com/hatan4ik/aws.modules.tgw/releases/tag/v1.1.0) | Acceptance receipts and spoke-route activation are released; no Network root consumes them yet. |
| VPC foundations | [aws.modules.vpc](https://github.com/hatan4ik/aws.modules.vpc) | [`v1.1.1`](https://github.com/hatan4ik/aws.modules.vpc/releases/tag/v1.1.1) | Active sandbox-network root remains pinned to `v1.0.0`; upgrade requires a reviewed plan. |
| WAF web ACLs | [aws.modules.waf](https://github.com/hatan4ik/aws.modules.waf) | [`v2.0.0`](https://github.com/hatan4ik/aws.modules.waf/releases/tag/v2.0.0) | Released edge-security leaf and blueprint dependency; no direct active-root consumer. |

## Fleet release audit

The table above was verified against GitHub on October 8, 2026. Every listed
release is an annotated semantic-version tag whose SSH signature GitHub marks
valid; the tag target, repository `main`, and latest published GitHub Release
all resolve to the same commit.

Run the same read-only check locally with an authenticated GitHub CLI:

```bash
scripts/verify-module-release-fleet.sh
```

The `module-release-fleet-audit.yml` workflow also runs this check weekly and
on demand. A newly created `aws.modules.*` repository is discovered
automatically and fails the audit until it has a current signed tag and
matching published release.

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
