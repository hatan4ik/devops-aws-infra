# Chapter 8 — Cost Model and FinOps

**Status:** Planning input — not a quote or budget approval.
**Authoritative source:** [architecture cost estimate](../architecture/cost-estimate.md)

This chapter deliberately does not copy prices, totals, or service formulas.
Those values change with AWS pricing, selected Regions, workload measurements,
and enterprise discounts; the architecture cost estimate is the single source
that must be updated and reviewed with each material design change.

## 8.1 Required decision record

Before any apply, the change record must contain:

1. A current AWS Pricing Calculator estimate for the selected account and
   Region with actual request, GB, retention, task, and endpoint inputs.
2. A comparison against the authoritative architecture model, including every
   exclusion and change in assumption.
3. Named budget and FinOps owners, Budgets, and Cost Anomaly Detection.
4. Approval for paid fixed-cost services, including inspection/egress, TGW/VPN,
   Global Accelerator, and any DDoS or fraud-control options.
5. For the transitional state backend, a first-30-day Cost Explorer/CUR
   baseline and a named owner, as required by ADR 0015.

## 8.2 Cost control boundaries

- A planning value is never capacity evidence; load tests and quota evidence
  remain separate acceptance criteria.
- The platform does not create paid network, identity, data, or security
  services by default from this repository.
- A cost exception must name its product owner, duration, rollback/retirement
  condition, and follow-up date.
- State-backend retention and lock transitions are governed by ADRs 0015 and
  0016 and must not be optimized by deleting recoverability controls.
