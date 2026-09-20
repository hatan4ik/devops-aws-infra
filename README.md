# AWS platform GitOps source

This repository contains the candidate GitOps source and documentation for a
proposed AWS-native, multi-account, two-Region platform. It does not contain
cloud credentials, state, or customer data, and it is not evidence that the
application platform has been deployed.

## Start here

Read [Project status and delivery authority](docs/PROJECT-STATUS.md) first. It
names the only current source-of-truth documents, the selected first milestone,
and the stop conditions that prevent accidental AWS changes.

## Current operating boundary

- The root [Terraform quality workflow](.github/workflows/terraform-quality.yml) is credential-free. It validates and tests Terraform, scans IaC, checks generated documentation, and verifies reusable-workflow policy.
- The plan, apply, drift, and release workflows are staged under [`automation/terraform-pipelines`](automation/terraform-pipelines/). They remain disabled until each canonical root has a reviewed backend and least-privilege role policy.
- Protected `main`, the `dev`, `staging`, `prod`, and `landing-zone` GitHub environments, and a sandbox permissionless GitHub OIDC trust proof are live under [ADR 0017](docs/adr/0017-github-oidc-bootstrap-proof.md). No Terraform backend, plan/apply/drift delivery role permission, or release tag is configured.
- Cognito MRR is intentionally blocked until it has a provider-backed Terraform lifecycle; see [ADR 0011](docs/adr/0011-cognito-mrr-provider-boundary.md).
- [`terraform/`](terraform/README.md) is the only candidate Terraform delivery tree. Root-level [`modules/`](modules/README.md) and [`roots/`](roots/README.md) are disabled historical prototypes; see [ADR 0014](docs/adr/0014-canonical-architecture-and-iac-boundary.md).

## Documentation authority

- [Project status](docs/PROJECT-STATUS.md) answers what is current and what
  happens next.
- [ADRs](docs/adr/README.md) control architecture and delivery decisions.
- [First delivery slice](docs/delivery/first-delivery-slice.md) bounds the work
  before platform expansion.
- [`docs/book/`](docs/book/README.md) is explanatory reference material only;
  it is not current status or approval authority.

## Two working lanes

1. [`docs/`](docs/README.md) is the operating lane for current status, ADRs,
   prerequisites, delivery contracts, and controlled runbooks.
2. [`terraform/`](terraform/README.md) is the sole candidate Terraform delivery
   lane. It remains backend-externalized and unapplied until the stated gates
   are satisfied.

`automation/` is future-pipeline template source. Root `modules/` and `roots/`
are disabled prototype/recovery evidence. `reference/`, `docs/book/`, and
`docs/reviews/archive/` are reference or historical material, not delivery
lanes.

## Repository map

| Directory | Contents |
|---|---|
| [`docs/architecture`](docs/architecture/README.md) | Architecture, threat/security controls, costs, prerequisites, and traceability. |
| [`docs/adr`](docs/adr/) | Active and proposed architecture decisions, their gates, and rejected alternatives. |
| [`docs/runbooks`](docs/runbooks/README.md) | Account vending, Region expansion, hybrid VPN/BGP, failover, and break-glass operations. |
| [`terraform`](terraform/README.md) | Candidate reusable modules, internal composition, and ten backend-externalized roots. |
| [`automation/terraform-pipelines`](automation/terraform-pipelines/README.md) | SHA-pinned quality/plan/apply/drift/release pipeline source and caller templates. |
| [`tests`](tests/README.md) | Mocked module, read-only AWS, public synthetic, and AuthN/AuthZ test contracts. |

## Before enabling AWS delivery

Follow the [external verification checklist](docs/architecture/external-verification.md) and [Phase 6–7 traceability](docs/architecture/phase-6-7-traceability.md). At minimum, the organization/account design, selected Regions, CIDR/ASN/prefix plan, state retention, KMS ownership, DNS/certificates, OIDC roles, GitHub protection/environments, service quotas, workload/data design, and cost approval must be supplied and approved.

Do not add credentials or production values to `terraform.tfvars`, source control, workflow logs, or CI artifacts.
