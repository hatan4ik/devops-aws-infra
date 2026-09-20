# Project status and delivery authority

**Status as of 2026-09-20:** design and candidate Terraform source are under
version control; this repository is **not** proof of a deployed application
platform. The sandbox account contains the permissionless GitHub OIDC provider
and trust roles established by ADR 0017, plus the observed legacy state
bootstrap. Neither is an application, network, identity, or data-plane
deployment. The state bootstrap adoption remains gated and unexecuted.

## Start here

This document is the current operating status. Read it before a design chapter,
review snapshot, or Terraform directory.

| Question | Authoritative location |
|---|---|
| What is true now and what happens next? | This status document |
| Which architecture decision controls a change? | [ADR index](adr/README.md) |
| Which Terraform tree may become delivery source? | [`terraform/`](../terraform/README.md) only |
| What is the first bounded delivery slice? | [First delivery slice](delivery/first-delivery-slice.md) |
| What evidence is required before an AWS apply? | [External verification checklist](architecture/external-verification.md) |
| How is the selected legacy backend adopted safely? | [Adoption runbook](runbooks/adopt-legacy-state-backend.md) |
| What is the credential-free quality evidence? | [Terraform quality workflow](../.github/workflows/terraform-quality.yml) |

## Current delivery decision

**Selected milestone:** adopt the observed legacy S3/KMS/DynamoDB Terraform
state bootstrap into the transitional canonical root, then harden or replace it
under separate approved changes. This is the decision in
[ADR 0015](adr/0015-adopt-legacy-state-bootstrap.md); retirement is not the
selected path.

This decision does **not** authorize a Terraform apply, a state move, import,
or any other AWS mutation. Execution remains blocked until the adoption
runbook's preconditions are evidenced: protected state backup, no active lock,
a reviewed no-resource-change plan, named Cloud Architecture/Security/SRE
approvals, and named cost ownership. GitHub has successfully proven its
permissionless sandbox OIDC session, but there is no Terraform delivery role
policy, backend configuration, remote plan, or apply pipeline.

## Delivery lanes

| Lane | Role | Do not treat it as |
|---|---|---|
| [`terraform/`](../terraform/README.md) | Candidate canonical Terraform delivery source. | An initialized backend or permission to apply. |
| [`docs/`](README.md) | Current decisions, prerequisites, runbooks, and delivery contracts. | Evidence that AWS services are deployed. |
| [`automation/terraform-pipelines/`](../automation/terraform-pipelines/README.md) | Reviewed workflow source for this repository's future root-specific delivery callers. | Active Terraform plan/apply/drift delivery. |
| Root [`modules/`](../modules/README.md) and [`roots/`](../roots/README.md) | Disabled historical prototypes retained as forensic input. | A deployment path. |
| [`docs/book/`](book/README.md) | Explanatory design reference. | Status, approval, or implementation authority. |
| [`docs/reviews/archive/`](reviews/archive/README.md) | Historical point-in-time assessments. | A current backlog or current repository state. |

## Next milestone and stop conditions

1. Record the completed GitHub OIDC proof and protect it with periodic review;
   do not attach AWS permissions before a root-specific policy change.
2. Complete the [first delivery slice](delivery/first-delivery-slice.md):
   establish the external evidence package and prepare the adoption change
   record.
3. Execute the legacy state-address adoption only after every stated gate has
   passed; record the no-change and restore evidence.
4. Only then prepare one sandbox network-root plan. Do not expand to production
   networking, application, identity, or multi-Region deployment before that
   bounded plan is reviewed.

Stop immediately if the backend lock is active, a plan changes resources, an
approval/evidence item is absent, or the required organization/network/CIDR
inputs are unresolved. Escalate the exception through the approved change
record; do not work around it with manual state commands.

## Verified local evidence

The credential-free quality workflow is the repository's current automated
evidence for formatting, validation, mocked Terraform tests, policy scans, and
workflow checks. It validates source quality only; it does not authenticate to
AWS and cannot establish deployment equivalence or authorize an apply.

The [sandbox OIDC proof workflow](../.github/workflows/oidc-sandbox-proof.yml)
is separately verified remote evidence: it assumed the environment-scoped role
and called only `sts:GetCallerIdentity`. The role has no inline or attached
identity policies and cannot provision infrastructure.
