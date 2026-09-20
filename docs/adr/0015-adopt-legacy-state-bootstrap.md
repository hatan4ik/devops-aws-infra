# ADR 0015: Adopt the legacy Terraform state bootstrap as a transitional canonical foundation

**Status:** Proposed — source is ready for review; no specialist quorum has
approved a remote-state mutation.
**Decision date:** 2026-09-19

## Context

Read-only discovery found a protected Terraform bootstrap in the approved AWS
account and `us-east-2`: one versioned, SSE-KMS encrypted S3 bucket with all
public-access blocks, Bucket Owner Enforced ownership, and 14-day Compliance
Object Lock; one customer-managed, rotating KMS key and alias; and one
on-demand DynamoDB lock table with point-in-time recovery and SSE-KMS. It
contains one state object and no bucket policy. The inventory is recorded in
[the legacy state bootstrap record](../architecture/legacy-state-bootstrap.md).

The state currently has nine historical Terraform bindings in the disabled
prototype tree: eight AWS resources plus one `random_id` helper. The canonical
`internal/state-backend` module deliberately describes a stricter, three-tier,
cross-Region design and cannot represent this bootstrap as a no-change import.
Treating that planned design as though it already owned the bootstrap would
hide a state-address migration and the unapproved changes required for logging,
role policies, replication, and a recovery Region.

## Options considered

1. **Adopt the observed bootstrap with a transitional canonical root, then
   harden/migrate it under separate approved changes.** Preserves the only
   current state copy and creates a truthful ownership record.
2. Retire the bootstrap. Rejected because the retained state may be required,
   Compliance Object Lock prevents a quick rollback, and no replacement
   backend or migration proof exists.
3. Import the resources directly into the three-tier state module. Rejected
   because it would misrepresent a substantial infrastructure migration as a
   no-change state import.

## Quorum review

| Role | Recorded position |
|---|---|
| Platform owner | Approved option 1 on 2026-09-19. |
| Cloud Architect | Required to review the state-address migration and its no-change plan before remote-state mutation. |
| Security Engineer | Required to approve post-adoption bucket/key access policy, central logging, retention, and break-glass roles. |
| SRE | Required to approve restore evidence and the state-backend failure-mode/runbook update. |
| Platform/DevOps Lead | Owns the runbook, GitOps source, change record, and cost-allocation evidence. |
| Network Engineer | No routing change; informed, with no required approval for the adoption-only change. |

Only the Platform Owner position is recorded. The other four specialist
positions above are open gates, not approvals. There is therefore no recorded
quorum or dissent result for a state mutation.

## Decision

1. [`terraform/roots/foundation/region-a/bootstrap-state/`](../../terraform/roots/foundation/region-a/bootstrap-state/)
   and its internal module are the sole canonical, transitional source for
   this bootstrap. The root has an empty S3 backend block and receives all
   backend configuration only from an uncommitted, approved runtime file.
2. The adoption source mirrors the observed resource settings and uses
   `prevent_destroy` for the bucket, KMS key, and lock table. It does not
   create, delete, import, move, or reconfigure AWS resources by itself.
3. The existing remote state may be re-addressed from the disabled prototype
   only through the [adoption runbook](../runbooks/adopt-legacy-state-backend.md),
   after a protected backup, an approved state-change record, and a reviewed
   no-resource-change plan. The helper `random_id` is removed from state only
   after the bucket name has been proven fixed and the backup has been checked.
4. The Platform/DevOps Lead is the operational owner. Until a named FinOps
   owner is assigned, that role also owns the monthly cost baseline and tags:
   `Project=platform-aws-platform`, `Environment=shared`, and
   `Layer=shared-services`. A Cost Explorer/CUR line item and owner must be
   recorded in the state-change evidence before the first post-adoption
   hardening apply. The transitional-backend cost record is maintained in the
   [cost model](../architecture/cost-estimate.md#transitional-state-backend).
5. The bootstrap is a transitional foundation, not the final state design. A
   later, separately approved migration must supply a Log Archive destination,
   TLS-and-principal-restricted bucket/key policies, DynamoDB deletion
   protection, cross-Region recovery, and a tested restore procedure before
   it is used as the platform-wide delivery backend.

## Delivery milestone selection

The Platform Owner's approved option 1 is the first delivery milestone for this
repository. It has a strict order: (1) complete the external evidence package,
(2) perform the approved no-change state-address adoption, and only then (3)
prepare one sandbox network-root plan. Retirement is not the selected milestone
because the retained state may be required and no replacement backend or
migration proof exists.

This ordering is a planning decision, not authorization to mutate AWS. The
specialist quorum, active-lock check, protected backup, no-resource-change plan,
and recovery/cost evidence in this ADR and the adoption runbook remain mandatory.
No application, identity, data-plane, production network, or multi-Region
platform expansion is authorized before the adoption evidence is accepted.

## Consequences

- The existing state backend has a canonical source location without pretending
  that the future multi-Region design already exists.
- A state-address move is an explicit, reviewable mutation rather than an
  implicit side effect of Terraform configuration changes.
- The disabled prototype and its local state artefacts remain forensic input
  until the migration evidence is accepted; they must not be used to operate
  the AWS resources. They may be quarantined only after the canonical backend
  passes the runbook’s completion checks.
- The source remains credential-free and no GitHub workflow is authorized to
  apply it. Human operators use short-lived IAM Identity Center credentials;
  CI remains blocked until ADR 0012 prerequisites are met.

## Delivery incident and transition exit criteria

During repository review, a root apply workflow was found on `origin/main`.
It has been converted to a manual preflight that exits before Terraform or AWS
credential configuration. This ADR records no evidence that the old workflow
changed an AWS resource. It is not authorization to retry delivery.

The transition is complete only when all of the following evidence is attached
to an approved change record: the protected state backup digest and S3 version
ID, no-resource-change plan, successful declarative state-address apply,
post-apply refresh-only plan, state-restore drill, a Cost Explorer/CUR baseline
with a named FinOps owner, and recorded approvals from Cloud Architecture,
Security, and SRE. Until then, the bootstrap root remains an adoption source,
not a platform delivery backend.
