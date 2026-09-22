# Terraform source

This directory separates code that GitHub Actions may execute from future
design source that may not be executed yet. It is not a Terraform root.
Read [Project status](../docs/PROJECT-STATUS.md) before using any root.

## Active

`active/` is the only executable Terraform delivery tree. The repository's
root GitHub Actions workflows reference only its five roots. Each reusable
implementation is an immutable, commit-pinned `aws.modules.*` Git source; this
repository deliberately contains no duplicate active module implementation.
It contains the delivered Organizations and sandbox-network roots plus the
Terraform-owned delivery IAM and sandbox-platform roots. GitHub OIDC is the
only supported apply path.

## Candidates

`candidates/` contains the future foundation, regional network, TGW, and
workload root composition. It has no dedicated plan, apply, or drift workflow. A
candidate becomes executable only through a separately approved ADR, backend
contract, least-privilege OIDC role, protected environment, root-specific
workflow, and reviewed plan.

## Safety boundary

- Never run `terraform apply` locally. Use the named GitHub workflow for an
  active root after its documented approval gate.
- Most deployment values belong in ignored `terraform.tfvars`; committed
  `terraform.tfvars.example` files are placeholders, not deployable values.
  The five active roots are the narrow exception: their reviewed, non-secret
  account/Region/CIDR contracts are versioned for their GitHub workflows.
- `active/root-context.yaml` is the reviewed, non-secret repository and
  allocation-tag context shared by active roots. It derives names and tags;
  it does not replace account, Region, backend, or OIDC trust boundaries.
- Provider credentials are short-lived GitHub OIDC credentials. Modules do not
  contain provider blocks, AWS credentials, account IDs, or remote-state data
  sources.
- `terraform test` uses provider mocks and `command = plan`; it does not
  create AWS resources. Terraform 1.7 or later is required.

## Layout

```text
active/roots/         Five roots referenced by root GitHub Actions workflows.
active/root-context.yaml  Shared static naming and tagging context for active roots.
candidates/modules/   Future root-composition modules only; implementations are external.
candidates/roots/     Future foundation, regional network, and workload roots.
```

Run the repository quality check with `scripts/validate-terraform-quality.sh`.
It formats, validates, and mock-tests the source without authenticating to AWS.
