# ADR 0012: Use separated OIDC roles and protected environments for Terraform delivery

**Status:** Accepted — Phase 6 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

Terraform plans must be reviewable, applies must be gated, state access must be isolated, and no long-lived AWS credential may be stored in GitHub. The platform also needs cost visibility, release provenance, and drift detection without an unattended remediation path. GitHub Actions supports short-lived AWS OIDC credentials and protected deployment environments, but the resulting AWS trust policy must use supported standard claims; AWS cannot enforce a GitHub custom claim for a reusable workflow.

## Options considered

1. Store static AWS credentials in repository or organization secrets and let one workflow role plan, apply, release, and remediate drift.
2. Use one broad OIDC administrator role with automatic applies and automatic drift remediation after any successful plan.
3. Use SHA-pinned reusable workflows and module sources; no-credential quality checks; separate least-privilege OIDC roles for plan, apply, and drift; protected GitHub environments for execution; plan/cost-diff review; signed immutable module release tags; and drift jobs that report/fail but never change AWS.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** Separate credentials and environment gates preserve account/Region blast-radius boundaries in the delivery path. |
| Network Engineer | **Approve 3.** A route or VPN change needs an explicit, serialized apply rather than an unattended response to detected drift. |
| Security Engineer | **Approve 3.** OIDC removes stored AWS keys, while narrow roles, immutable action pins, protected environments, and signed tags make delivery evidence reviewable. |
| SRE | **Approve 3.** A failed drift check creates an actionable signal without turning a monitoring workflow into an uncontrolled repair system. |
| Platform/DevOps Lead | **Approve 3.** Reusable quality/plan/apply/release interfaces provide a consistent control plane while preserving root-specific roles and state. |

**Result:** 5–0 for option 3; no dissent.

## Decision

Adopt option 3 and the workflow contracts in [terraform-pipelines](https://github.com/hatan4ik/terraform-pipelines). Quality uses no AWS identity. A plan uses a plan-only role and produces an Infracost base/head diff; an apply re-plans only after a protected `dev`, `staging`, or `prod` environment grants approval; drift uses a read-only role and exits non-zero when it detects a difference. Module releases verify a signed semantic-version tag before publishing release notes.

Every third-party action is pinned to a reviewed full commit SHA. No workflow prints, uploads, caches, or commits backend configuration or Terraform plan files. The backend configuration is ephemeral runner input, and all role/back-end/environment values are required caller configuration rather than defaults.

Before activation, AWS trust policies must bind `aud` to `sts.amazonaws.com` and `sub` to the exact repository plus protected environment or approved ref available in GitHub's standard OIDC claims. The remote preflight must prove that a caller cannot substitute an apply role in a plan workflow, that environment secrets are withheld until the gate is approved, and that the broadest allowed role still cannot perform unrelated operations. This local ADR does not claim those remote tests have passed.

## Consequences

- Option 1 is rejected: static keys are long-lived, hard to scope/audit, and conflict with the credential boundary in ADR 0008.
- Option 2 is rejected: a broad role and automatic remediation combines detection, authorization, and mutation; a faulty plan or drift signal could alter network, identity, state, or data controls without human review.
- Execution requires more remote configuration: per-root OIDC trust and resource policies, protected environments, narrow state access, caller review controls, on-call routing, and an immutable pipeline revision.
- A passing plan/cost diff remains a review artifact, never an apply authorization. A failed drift job creates an incident/change input; its remediation must pass normal review and environment gates.
