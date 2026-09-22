# AWS platform GitOps source

This repository is the GitOps source and operator documentation for an
AWS-native, multi-account, multi-Region platform. It contains no cloud
credentials, Terraform state, or customer data.

## Start here

Read [Project status and delivery authority](docs/PROJECT-STATUS.md) first.
It is the authority for what exists in AWS, what may be changed, and what is
still blocked.

## One executable path

```text
.github/workflows/  ->  infra/active/roots/  ->  aws.modules.*@immutable-tag
```

`infra/active` is the only executable Terraform delivery tree. Only the four
roots below are referenced by the root GitHub Actions workflows:

| Active root | Owning delivery workflow family |
|---|---|
| `organization/global` | `organization-{plan,apply,drift}.yml` |
| `sandbox-delivery/us-east-2/global` | `sandbox-delivery-iam-{plan,apply,drift}.yml` |
| `sandbox-network/us-east-2/dev` | `sandbox-network-{plan,apply,drift}.yml` |
| `sandbox-platform/us-east-2/dev` | `sandbox-platform-{plan,apply,drift}.yml` |

All applies require a manual dispatch, an explicit `apply` confirmation, the
protected GitHub environment, and short-lived GitHub OIDC credentials. Local
quality checks initialize with `-backend=false` and never apply.

## Repository map

| Directory | Purpose | Delivery status |
|---|---|---|
| [`infra/active`](infra/README.md) | Current roots that call versioned external modules. | Executable only through its named GitHub workflows. |
| [`infra/candidates`](infra/README.md#candidates) | Future root composition that calls versioned external modules. | Source-only; no root workflow may run it. |
| [Module repositories](docs/MODULE-REPOSITORIES.md) | Versioned `aws.modules.*` implementations and exact source tags. | Each module has its own quality workflow and release tag. |
| [`archive/prototypes`](archive/prototypes/) | Disabled predecessor modules and roots, each guarded to fail a normal plan. | Never deploy. |
| [`archive/cloudformation-sandbox-bootstrap`](archive/cloudformation-sandbox-bootstrap/) | Retired CloudFormation bootstrap evidence. | Never deploy. |
| [`tooling/pipeline-templates`](tooling/pipeline-templates/README.md) | Reusable workflow templates for a future pipeline-repository split. | Template-only. |
| [`docs`](docs/README.md) | Status, ADRs, runbooks, architecture, and evidence. | Operating authority. |
| [`tests`](tests/README.md) | Terraform contract and operational test contracts. | Quality evidence. |

## Documentation authority

- [Project status](docs/PROJECT-STATUS.md) — current verified AWS state and next gate.
- [ADRs](docs/adr/README.md) — architecture and delivery decisions.
- [First delivery slice](docs/delivery/first-delivery-slice.md) — bounded work before platform expansion.
- [`docs/book/`](docs/book/README.md) — explanatory reference only, not approval authority.

## Before enabling a new AWS delivery root

Follow the [external verification checklist](docs/architecture/external-verification.md)
and [Phase 6–7 traceability](docs/architecture/phase-6-7-traceability.md). Do
not add credentials or production values to `terraform.tfvars`, source
control, workflow logs, or CI artifacts.
