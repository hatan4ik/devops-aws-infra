# Changelog

All notable source changes are recorded here. This repository has not
published a reusable-module release; relative module sources remain a local
staging contract and must be tagged/published before external consumption.

## Unreleased

### Breaking / operationally significant

- `internal/state-backend` now protects state KMS keys, buckets, and DynamoDB
  tables with `prevent_destroy`. Removing those resources requires an explicit
  lifecycle change and a reviewed migration plan.
- Legacy state-backend adoption is a declarative, state-only migration with
  `moved`, `import`, and `removed` blocks. The former imperative state commands
  are no longer supported.

### Added

- Cross-platform provider locks, read-only lockfile validation, mandatory
  Terraform module tests, ShellCheck, actionlint, generated-doc drift checks,
  and contribution controls.
