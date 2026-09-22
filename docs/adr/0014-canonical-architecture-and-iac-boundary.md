# ADR 0014: Establish the canonical architecture record and Terraform delivery boundary

**Status:** Accepted
**Decision date:** 2026-09-19

## Context

The repository contains two independently written ADR series that reuse ADR
numbers 0001 through 0009. Both series were marked Accepted, but they reach
opposite decisions on account vending, public ingress, workload egress,
identity replication, observability ownership, and repository topology. A
archived Terraform tree under `archive/prototypes/` contains configured S3
backends, a named local credential profile, public-NAT topology, and
CloudFront-origin failover semantics that do not match the reviewed platform
source under `infra/`.

This makes an ADR citation ambiguous and risks an operator applying a prototype
instead of the reviewed platform source.

## Decision

1. The accepted, authoritative ADR sequence is:
   - [ADR 0001](0001-control-tower-account-vending.md) through
     [ADR 0013](0013-layered-verification-no-automatic-fault-injection.md).
2. The following files are retained only as historical records and are
   superseded by this ADR: `0001-account-structure.md`,
   `0002-multi-region-strategy.md`, `0003-compute-platform.md`,
   `0004-identity-provider.md`, `0005-egress-inspection.md`,
   `0006-edge-ingress.md`, `0007-fine-grained-auth.md`,
   `0008-observability.md`, and `0009-repository-strategy.md`.
3. [`infra/active/`](../../infra/README.md) is the only executable Terraform
   delivery tree. [`infra/candidates/`](../../infra/README.md#candidates) is
   source-only and still requires the documented approval and preflight process
   before a root can receive an AWS plan or apply workflow.
4. The [`archive/prototypes/`](../../archive/prototypes/) trees are disabled prototypes. They
   are not a module registry, are not a deployment path, and must fail a normal
   Terraform plan. Their configured remote backend and named-profile settings
   are removed.
5. A future change may promote a prototype only by first adding or amending an
   authoritative ADR, moving or re-implementing it in `infra/candidates/` or
   `infra/active/`, adding the
   applicable quality/security coverage, and obtaining the normal review and
   delivery approvals.

## Quorum record and promotion gate

The original repository decision recorded `Accepted` but did not preserve
role-level names, positions, or dissent. That acceptance is therefore limited
to the source-boundary decision above; it is not a quorum for an AWS mutation.

| Role | Recorded position for this ADR | Required before a promotion or live mutation |
|---|---|---|
| Platform owner | Boundary accepted; individual record not preserved in this file. | Approve the specific change record and accountable owner. |
| Cloud Architect | No role-level historical position recorded. | Confirm ADR/design consistency and migration scope. |
| Network Engineer | No role-level historical position recorded. | Review routing, DNS, TGW, or hybrid impact when applicable. |
| Security Engineer | No role-level historical position recorded. | Approve credentials, policy, retention, and control impact. |
| SRE | No role-level historical position recorded. | Approve observability, rollback, restore, and operational evidence. |
| Platform/DevOps Lead | No role-level historical position recorded. | Own GitOps delivery, evidence, and rollback implementation. |

Any dissent and its resolution must be added to the change ADR. Missing
historical names are not backfilled or inferred.

## Consequences

- ADR references have one unambiguous meaning and the traceability matrix can
  link only to active decisions.
- Operators cannot accidentally use the deprecated roots through their former
  backend configuration or a committed credential-profile name.
- Existing prototype files remain available for historical comparison without
  being represented as approved or deployable infrastructure.
- The canonical source keeps the no-implicit-apply, no-static-credential, and
  external-prerequisite boundaries established by ADRs 0008, 0011, 0012, and
  0013.

## Alternatives rejected

1. **Keep both ADR series Accepted.** Rejected because identical identifiers
   with incompatible decisions make design review and implementation evidence
   non-deterministic.
2. **Delete the later ADRs and prototype tree.** Rejected because preserving
   the record explains why they are unavailable and supports future migration
   analysis without restoring deployability.
3. **Treat the root-level tree as a second supported implementation.** Rejected
   because it conflicts with the approved landing-zone, egress, ingress,
   identity, state, and delivery decisions and has no equivalent quality gate.
