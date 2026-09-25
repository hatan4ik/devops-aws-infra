# ADR 0023: Protected sandbox application-plane teardown

**Status:** Accepted
**Decision date:** 2026-09-25

## Context

The sandbox currently has a deployed private network, platform services, and
an ECS workload. A rebuild must be possible without leaving unmanaged
resources or bypassing the existing GitHub OIDC delivery boundary. A local
`terraform destroy`, console deletion, or broad-account cleanup would either
evade the reviewed pipeline or risk removing the Organization, delivery
identity, and remote state that are needed to make the next build safely.

The platform ECR repository may contain application images. Its Terraform
module keeps force deletion disabled during normal operation, so a controlled
teardown needs a distinct, narrow image-purge action before Terraform can
delete that repository.

## Decision

1. A manually dispatched `sandbox-teardown.yml` is the sole supported delete
   path for the sandbox application plane. It runs only from protected `main`
   and uses the existing short-lived, root-specific GitHub OIDC roles.
2. The workflow requires a successful teardown-plan run from the same `main`
   commit, the exact application-plane confirmation, and a separate explicit
   acknowledgement for Cognito, ECR, DynamoDB, and log data loss.
3. It destroys only the workload, platform, and network roots in that order.
   The Organization root, sandbox delivery IAM root, state bucket, state KMS
   key, and lock table are excluded from the scope.
4. Immediately before each destroy, the reusable workflow saves an encrypted
   state snapshot inside the root's existing state prefix. It re-plans the
   checked-out protected revision and applies that binary plan once.
5. The platform destroy may purge image digests only from the ECR repository
   named by the platform Terraform output. The owning IAM module grants only
   `ecr:BatchDeleteImage` in addition to the pre-existing platform ECR
   lifecycle permissions; no administrator policy is introduced.
6. Under the same reviewed destroy request, the platform stage may deactivate
   deletion protection only for the Terraform output's Cognito user pool and
   DynamoDB session table. The Cognito request preserves the current accepted
   pool configuration before changing `DeletionProtection` to `INACTIVE`; the
   workflow verifies both protections are inactive before it creates the
   final binary destroy plan.
7. A repeated teardown is idempotent: a root that was already destroyed after
   an interrupted run reports zero planned deletes and proceeds as a no-op,
   while downstream roots remain ordered behind successful predecessors.

## Consequences

- A clean application-plane rebuild remains GitOps-managed and does not need
  a new AWS account, static credential, or console change.
- Teardown is intentionally not an account nuke: delivery identity and state
  remain available to review, recover, or rebuild the roots.
- The process irreversibly deletes application-plane data. The state snapshot
  is recovery evidence for Terraform state, not a restoration of Cognito
  users, DynamoDB records, ECR images, or logs.
- Any future full account/organization retirement needs its own ADR, account
  closure process, retention/export plan, and explicit approval; it must not
  be added as an option to this sandbox workflow.
