# Operational runbooks

These are the current executable procedures. A runbook does not authorize an
AWS change by itself; the normal plan, protected apply, and evidence gates
still apply.

| Runbook | Use |
|---|---|
| [AWS access bootstrap](bootstrap-aws-access.md) | Configure and verify short-lived IAM Identity Center access. |
| [GitHub Actions delivery](github-actions-delivery.md) | Plan, apply, and detect drift through root-specific GitHub OIDC workflows. |
| [Sandbox workload delivery](sandbox-workload-delivery.md) | Deliver and roll back a private Fargate service from an immutable ECR image. |
| [Terraform state restore](state-restore.md) | Recover Terraform state after a confirmed state incident. |
| [Break-glass access](break-glass-access.md) | Respond to an approved incident when normal access cannot restore service. |

Future account, TGW, VPN/BGP, regional, public-ingress, and production
operations are planned in the [roadmap](../ROADMAP.md), not represented as
half-supported runbooks.
