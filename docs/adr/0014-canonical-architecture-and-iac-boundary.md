# ADR 0014: Establish the canonical architecture record and Terraform delivery boundary

**Status:** Accepted
**Decision date:** 2026-09-19
**Cleanup amendment:** 2026-09-24

## Context

The original repository carried duplicate ADR numbers, disabled prototype
Terraform, copied external repositories, and future root drafts beside the
actual delivery code. That made citations ambiguous and obscured the only path
that could change AWS.

## Decision

1. The ADRs listed in [the ADR index](README.md) are the only architecture
   authority in this repository.
2. `infra/active/` is the only executable Terraform tree. It may reach AWS
   solely through its root-specific GitHub OIDC workflows.
3. Reusable implementation belongs in independently released `aws.modules.*`
   repositories and active roots consume only immutable commit pins.
4. Historical prototypes, duplicate ADRs, copied references, review snapshots,
   and unapproved candidate roots are removed from `main`. Git history retains
   them for forensic comparison; they must not be restored as a deployment path.
5. A future platform capability begins with an ADR amendment or new ADR, then
   a newly reviewed root, state boundary, least-privilege OIDC role, protected
   workflow, and plan. A document or historical code copy is not a capability.

## Consequences

- Operators have one source tree, one documentation set, and one delivery
  lifecycle to inspect.
- Git history remains the recoverable historical record without confusing it
  with current infrastructure.
- Any future TGW, VPN/BGP, account, multi-Region, or public-ingress work must
  be intentionally introduced rather than promoted from dormant source.

## Alternatives rejected

1. **Keep parallel trees marked as disabled.** Rejected because visible
   near-implementations were repeatedly mistaken for active code.
2. **Keep duplicate ADR series.** Rejected because identical identifiers could
   not be cited unambiguously.
3. **Use a local Terraform apply for speed.** Rejected because it bypasses the
   protected GitHub OIDC plan, approval, and evidence boundary.
