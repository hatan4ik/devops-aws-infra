# Operational runbooks

These are the current executable procedures. A runbook does not authorize an
AWS change by itself; the normal plan, protected apply, and evidence gates
still apply.

## Operator sequence

1. Confirm the latest evidence date and current gate in
   [Project status](../PROJECT-STATUS.md).
2. Confirm the role, delivery order, and stop conditions in the
   [ConOps](../operations/conops.md).
3. Read the affected active root README and its pull-request plan.
4. Follow exactly one runbook below; stop if its prerequisites are not met.
5. Verify the result, collect no-change or drift evidence, and update project
   status when the observed AWS state changed.

| Runbook | Use |
|---|---|
| [AWS access bootstrap](bootstrap-aws-access.md) | Configure and verify short-lived IAM Identity Center access. |
| [GitHub Actions delivery](github-actions-delivery.md) | Plan, apply, and detect drift through root-specific GitHub OIDC workflows. |
| [Sandbox application-plane teardown](sandbox-teardown.md) | Produce a reviewed destroy plan and, after explicit data-loss acknowledgement, remove workload, platform, and network while retaining the control plane. |
| [Sandbox workload delivery](sandbox-workload-delivery.md) | Deliver and roll back a private Fargate service from an immutable ECR image. |
| [Terraform state restore](state-restore.md) | Recover Terraform state after a confirmed state incident. |
| [Break-glass access](break-glass-access.md) | Respond to an approved incident when normal access cannot restore service. |

Future account, TGW, VPN/BGP, regional, public-ingress, and production
operations are planned in the [roadmap](../ROADMAP.md), not represented as
half-supported runbooks.
