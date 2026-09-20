# Candidate canonical Terraform delivery source

This is the repository's only candidate Terraform delivery tree. It holds the
stakeholder-approved local Phase 5 source before the approved repository set
exists remotely. It is not a Terraform root itself and has no remote backend.
Read [Project status](../docs/PROJECT-STATUS.md) and the
[first delivery slice](../docs/delivery/first-delivery-slice.md) before using
any root. On remote-creation approval, each `modules/terraform-aws-*` directory
is moved intact to its corresponding module repository; `roots/` and
`modules/internal/` are split into their owning live-configuration repositories
as defined in [the repository strategy](../docs/architecture/repository-strategy.md).

## Safety boundary

- No directory is initialized against an AWS backend by default. Each root has `backend "s3" {}` with configuration supplied only after account vending and state-backend bootstrap.
- `terraform.tfvars` is uncommitted and contains only approved deployment values. Use the committed `terraform.tfvars.example` as a non-secret placeholder and shape reference; do not treat placeholder values as deployable configuration.
- Provider credentials come from a root-level AWS provider and are intended to be short-lived GitHub OIDC credentials. No module contains a provider block, AWS credential, account ID, or remote-state data source.
- `terraform test` uses provider mocks and `command = plan`; it does not create AWS resources. It requires Terraform 1.7 or later because provider mocking was introduced in that release.

## Layout

```text
modules/terraform-aws-*/   Candidate independently released module repositories.
modules/internal/          Composition owned by a live configuration; not a registry contract.
roots/                     One root per account, Region, and environment tuple.
```

Run formatting from this directory with `terraform fmt -recursive`. Run an individual module's tests from its directory after installing a Terraform version that satisfies its `versions.tf` constraint.
