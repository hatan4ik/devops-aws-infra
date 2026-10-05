# Sustainability Pillar Assessment

## Executive Summary

The current AWS footprint is small, with no active Sandbox compute fleet or
application data plane. That avoids immediate resource waste, but there is no
workload-level utilization baseline, sustainability KPI, retention policy
evidence, or method to measure resources per user/request. Sustainability must
be designed into the first workload rather than retrofitted at millions of
users.

**Risk profile:** High 0; Medium 2; Improvement opportunities 2.

AWS sustainability guidance uses resources provisioned per unit of work as a
key metric and requires a baseline before measuring improvements.
[Sustainability measurement guidance](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/evaluate-specific-improvements.html).

## Detailed findings

### SUS-01 — No resource-per-unit-of-work sustainability baseline

1. **Risk level:** Medium.
2. **Description:** No workload metrics, user/request volume, compute
utilization, storage growth, network transfer, cache efficiency, or cost per
user were available because no application plane is deployed.
3. **Affected resources:** Future application compute, storage, network, and
   data services.
4. **Best-practice reference:** Measure resources provisioned per business
   outcome.
5. **Business impact:** The organization cannot identify whether user growth
   improves utilization or simply increases idle capacity and data transfer.
6. **Recommendation:** Define sustainability KPIs alongside performance and
   cost KPIs before the first production-like workload is launched.
7. **Implementation steps:** Record active users, requests, transactions, vCPU
   minutes, GB stored, GB transferred, cache hits, and consumed capacity; report
   ratios such as vCPU-minutes/request and GB/request monthly; compare each
   release to the baseline.
8. **Estimated effort:** Medium.
9. **Expected outcome:** Engineering choices can reduce resources required per
   customer outcome.

### SUS-02 — Storage, logging, and data-retention lifecycle is not yet defined organization-wide

1. **Risk level:** Medium.
2. **Description:** State buckets show strong encryption/versioning/Object Lock
   controls, but no central Log Archive account, organization CloudTrail,
   workload log retention, data classification, or lifecycle standard exists.
3. **Affected resources:** Future CloudTrail, Config, VPC Flow Logs,
   application logs, backups, objects, and DynamoDB backups.
4. **Best-practice reference:** Use data storage patterns and lifecycle policy
   appropriate to access/retention requirements.
5. **Business impact:** Retaining data indefinitely increases cost and storage
   footprint; deleting too early harms audit/recovery obligations.
6. **Recommendation:** Define retention tiers by data class before central logs
   and application data are created.
7. **Implementation steps:** Set explicit hot/query, archive, and deletion
   periods for security logs, application logs, backups, and user data;
   document legal/compliance owners; automate lifecycle policies; review data
   growth and retrieval demand quarterly.
8. **Estimated effort:** Medium.
9. **Expected outcome:** Reduced storage footprint while preserving required
   forensic and recovery evidence.

## Improvement opportunities

| Opportunity | Evidence | Recommendation |
|---|---|---|
| Use managed elasticity rather than always-on fleets. | No existing compute fleet needs migration; intended services include managed AWS-native options. | Prefer demand-based/serverless or autoscaled managed services where access patterns support them; right-size from telemetry. |
| Avoid idle multi-Region infrastructure. | No TGWs or application infrastructure exist today. | Build the secondary hub/spokes only when DR/latency testing justifies them; regularly verify recovery resources remain proportionate to RTO/RPO. |

## Prioritized action plan

1. **0-30 days:** Add retention and lifecycle decisions to the Log Archive and
   data-classification design.
2. **30-90 days:** Instrument resource-per-request/user metrics with the first
   Sandbox workload.
3. **90+ days:** Review utilization, storage, and transfer KPIs quarterly;
   apply validated reductions across accounts/Regions.
