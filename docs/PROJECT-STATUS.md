# Project status and delivery authority

**Status as of 2026-09-20:** design and candidate Terraform source are under
version control; this repository is **not** proof of a deployed application
platform. The only infrastructure observed in the approved AWS account is a
legacy state bootstrap. Its adoption is selected as the first delivery
milestone, but its remote state-address migration is still gated and has not
been executed.

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
approvals, and named cost ownership. The current repository has no active
OIDC delivery identity or remote plan/apply pipeline.

## Delivery lanes

| Lane | Role | Do not treat it as |
|---|---|---|
| [`terraform/`](../terraform/README.md) | Candidate canonical Terraform delivery source. | An initialized backend or permission to apply. |
| [`docs/`](README.md) | Current decisions, prerequisites, runbooks, and delivery contracts. | Evidence that AWS services are deployed. |
| [`automation/terraform-pipelines/`](../automation/terraform-pipelines/README.md) | Reviewed templates for a future, dedicated pipeline repository. | Active CI/CD delivery. |
| Root [`modules/`](../modules/README.md) and [`roots/`](../roots/README.md) | Disabled historical prototypes retained as forensic input. | A deployment path. |
| [`docs/book/`](book/README.md) | Explanatory design reference. | Status, approval, or implementation authority. |
| [`docs/reviews/archive/`](reviews/archive/README.md) | Historical point-in-time assessments. | A current backlog or current repository state. |

## Next milestone and stop conditions

1. Complete the [first delivery slice](delivery/first-delivery-slice.md):
   establish the external evidence package and prepare the adoption change
   record.
2. Execute the legacy state-address adoption only after every stated gate has
   passed; record the no-change and restore evidence.
3. Only then prepare one sandbox network-root plan. Do not expand to production
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
