# Retired generic workflow preflights

These two files are retained as historical evidence of the delivery gate that
existed before root-specific GitHub OIDC workflows were active. They
intentionally exit nonzero and must not be restored to `.github/workflows/`.

- `terraform-apply.yml` was a manual delivery preflight.
- `terraform-drift.yml` was a manual drift-detection preflight.

The active workflows are root-specific and live in
`.github/workflows/{organization,sandbox-delivery-iam,sandbox-network,sandbox-platform}-{plan,apply,drift}.yml`.
Reusable generic workflow source for a future pipeline repository lives under
[`tooling/pipeline-templates/`](../../tooling/pipeline-templates/).
