# ADR 0015: Adopt the legacy Terraform state bootstrap

**Status:** Closed — historical adoption completed; no reusable procedure remains.

## Decision

The observed legacy Terraform state bootstrap was adopted only through a
reviewed, state-preserving migration. The resulting active roots own their
state through isolated GitHub OIDC delivery workflows. The previous bootstrap
prototype and its migration artifacts are retained in Git history only.

No operator may recreate the historical adoption path, edit state locally, or
use it as a template for a new backend. A new state backend requires a new
root, reviewable Terraform source, least-privilege delivery identity, a
protected plan/apply workflow, and the current [state restore runbook](../runbooks/state-restore.md).

## Consequences

- `infra/active` remains the sole delivery tree.
- The current source contains no mutable state, plan files, or historical
  local-profile configuration.
- A state incident follows the current restore procedure, not the retired
  adoption procedure.
