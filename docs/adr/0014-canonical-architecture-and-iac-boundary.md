# ADR 0014: Establish the canonical architecture record and Terraform delivery boundary

**Status:** Accepted
**Decision date:** 2026-09-19

## Context

The repository contains two independently written ADR series that reuse ADR
numbers 0001 through 0009. Both series were marked Accepted, but they reach
opposite decisions on account vending, public ingress, workload egress,
identity replication, observability ownership, and repository topology. A
second Terraform tree at the repository root (`modules/` and `roots/`) follows
the later series and contains configured S3 backends, a named local credential
profile, public-NAT topology, and CloudFront-origin failover semantics that do
not match the reviewed platform design under `terraform/`.

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
3. Only [`terraform/`](../../terraform/README.md) is a candidate Terraform
   delivery tree. It is backend-disabled, credential-free source and still
   requires the documented approval and preflight process before any AWS plan
   or apply.
4. The root-level `modules/` and `roots/` trees are disabled prototypes. They
   are not a module registry, are not a deployment path, and must fail a normal
   Terraform plan. Their configured remote backend and named-profile settings
   are removed.
5. A future change may promote a prototype only by first adding or amending an
   authoritative ADR, moving or re-implementing it in `terraform/`, adding the
   applicable quality/security coverage, and obtaining the normal review and
   delivery approvals.

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
