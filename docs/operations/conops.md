# Platform Concept of Operations

## Scope

This ConOps governs the current private sandbox in `us-east-2`. It is the
operating model for GitOps delivery, verification, and recovery. The future
multi-account, multi-Region, TGW, and VPN architecture is intentionally not an
executable path until the roadmap gates are complete.

## Reference answers

| Topic | Current answer |
|---|---|
| What controls AWS? | Only the five roots in `infra/active`, invoked by their matching protected GitHub workflow. |
| How do humans authenticate? | AWS IAM Identity Center, using short-lived SSO profiles. |
| How does CI authenticate? | Environment-scoped GitHub OIDC roles. No static AWS keys are stored in GitHub or this repository. |
| What network exists? | A private `10.64.0.0/16` sandbox VPC with two private subnets and endpoint-only AWS service access. |
| How is an app delivered? | An application repository publishes an immutable ECR digest; the workload root supplies its typed task contract and a reviewed GitOps plan. |
| What is deliberately absent? | Public ingress, NAT/Internet egress, Control Tower, additional accounts, TGW, VPN/BGP, a second Region, and production. |

## Change lifecycle

1. Supply an immutable image digest, task size, health contract, capacity,
   private dependencies, secret references, and minimum IAM needs.
2. Change one active root or one released module pin. Open a pull request.
3. Review the credential-free quality checks and the matching OIDC Terraform
   plan. Treat unexpected replacement, destroy, public addressing, broad IAM,
   or account/Region mismatch as a stop condition.
4. Merge to protected `main`. Dispatch the matching `*-apply.yml` workflow,
   type `apply`, and obtain protected-environment approval.
5. Verify the intended resource/service behavior, then run the matching plan
   or drift workflow. A green workflow alone is not application health proof.

## Delivery order

`organization` → `sandbox-delivery` → `sandbox-network` →
`sandbox-platform` → application image → `sandbox-workload`.

Each root has independent remote state and an OIDC role. Do not apply a later
root when the prior dependency is unplanned, unhealthy, or drifting.

## Roles

| Role | Owns | Cannot bypass |
|---|---|---|
| Platform owner | Roots, module pins, workflow contracts, and evidence. | Protected review or environment approval. |
| Application owner | Digest, health contract, configuration, and rollback revision. | Network, OIDC trust, or delivery-IAM changes. |
| Security owner | Least privilege, secret access, domains, ingress, and production exposure. | Live verification requirements. |
| On-call/SRE | Service events, logs, CloudTrail, drift results, and incident evidence. | Local Terraform apply or manual state changes. |

## Recovery

Roll back an application with a reviewed change to a prior immutable image
digest. The ECS deployment circuit breaker handles a failed rollout. State
recovery is exceptional work governed by the [state restore runbook](../runbooks/state-restore.md); it never authorizes console changes or an unreviewed
state edit.
