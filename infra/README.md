# Active Terraform roots

`infra/active` is the only Terraform delivery tree in this repository. It is
not a Terraform root itself; run the root-specific GitHub workflow listed in
the top-level [README](../README.md) after a reviewed pull request.

## Rules

- One root represents one account, Region, and environment boundary.
- Roots compose released `aws.modules.*` implementations through immutable
  commit-SHA sources. They do not duplicate reusable module code.
- Root state is isolated. Do not read or edit state locally.
- A root may reach AWS only through its matching GitHub OIDC workflow.
- `root-context.yaml` contains reviewed, non-secret naming and allocation tags;
  it is not an identity, account, backend, or credential source.

Run `scripts/validate-terraform-quality.sh` for credential-free formatting,
validation, tests, linting, and delivery-boundary checks. It initializes roots
with `-backend=false` and never plans or applies remote state.
