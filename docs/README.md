# Platform documentation

Start with [Project status and delivery authority](PROJECT-STATUS.md). It
separates current truth from design reference and historical material.

## Operating documents

- [Architecture decisions](adr/README.md) — the decision authority; ADR 0015
  selects the first delivery milestone.
- [First delivery slice](delivery/first-delivery-slice.md) — the bounded work
  that must complete before platform expansion.
- [External verification checklist](architecture/external-verification.md) —
  inputs and approvals required before any AWS apply.
- [Runbooks](runbooks/README.md) — controlled operational procedures; a
  runbook is not automatic authorization to execute an AWS change.
- [Versioned module repositories](MODULE-REPOSITORIES.md) — the reusable
  `aws.modules.*` implementations, their immutable release commits, and the
  consumer-source rule.

## Reference and history

- [Engineering reference](book/README.md) explains the target design. It is
  not current deployment status or an approval record.
- [Historical reviews](reviews/README.md) are preserved evidence only. Their
  findings must be reconciled against current decisions and source before work
  is scheduled.
