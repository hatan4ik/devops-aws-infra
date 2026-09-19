# AWS platform GitOps source

This repository is the GitOps source for a proposed AWS-native, multi-account, two-Region platform. It contains reviewed architecture, Terraform module/root source, local pipeline definitions, runbooks, and verification contracts. It does not contain cloud credentials, state, or customer data. A legacy AWS state bootstrap is recorded by a transitional canonical root; its approved adoption boundary and still-gated state-address migration are in the [legacy state bootstrap inventory](docs/architecture/legacy-state-bootstrap.md).

## Current operating boundary

- The root [Terraform quality workflow](.github/workflows/terraform-quality.yml) is credential-free. It validates and tests Terraform, scans IaC, checks generated documentation, and verifies reusable-workflow policy.
- The plan, apply, drift, and release workflows are staged under [`automation/terraform-pipelines`](automation/terraform-pipelines/) for a future dedicated pipeline repository. They are not active deployment paths in this repository.
- No Terraform backend configuration, plan, apply, GitHub environment, OIDC role, branch ruleset, or release tag is configured by this source alone. The one observed legacy state bootstrap is not evidence of a deployed application platform and remains pending its canonical state-address migration.
- Cognito MRR is intentionally blocked until it has a provider-backed Terraform lifecycle; see [ADR 0011](docs/adr/0011-cognito-mrr-provider-boundary.md).
- [`terraform/`](terraform/README.md) is the only candidate Terraform delivery tree. Root-level [`modules/`](modules/README.md) and [`roots/`](roots/README.md) are disabled historical prototypes; see [ADR 0014](docs/adr/0014-canonical-architecture-and-iac-boundary.md).

## Engineering reference documentation

A full O'Reilly-style engineering reference is available in [`docs/book/`](docs/book/README.md). It covers platform overview, architecture diagrams, network/security design, identity/compute/data, CI/CD pipeline, Terraform module catalog, SRE/observability, cost model, ADR index, runbooks, verification strategy, and the pre-deployment checklist.

## Repository map

| Directory | Contents |
|---|---|
| [`docs/architecture`](docs/architecture/README.md) | Architecture, threat/security controls, costs, prerequisites, and traceability. |
| [`docs/adr`](docs/adr/) | Accepted architecture decisions and their rejected alternatives. |
| [`docs/runbooks`](docs/runbooks/README.md) | Account vending, Region expansion, hybrid VPN/BGP, failover, and break-glass operations. |
| [`terraform`](terraform/README.md) | Candidate reusable modules, internal composition, and ten backend-disabled roots. |
| [`automation/terraform-pipelines`](automation/terraform-pipelines/README.md) | SHA-pinned quality/plan/apply/drift/release pipeline source and caller templates. |
| [`tests`](tests/README.md) | Mocked module, read-only AWS, public synthetic, and AuthN/AuthZ test contracts. |

## Before enabling AWS delivery

Follow the [external verification checklist](docs/architecture/external-verification.md) and [Phase 6–7 traceability](docs/architecture/phase-6-7-traceability.md). At minimum, the organization/account design, selected Regions, CIDR/ASN/prefix plan, state retention, KMS ownership, DNS/certificates, OIDC roles, GitHub protection/environments, service quotas, workload/data design, and cost approval must be supplied and approved.

Do not add credentials or production values to `terraform.tfvars`, source control, workflow logs, or CI artifacts.
