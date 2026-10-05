# Cost Optimization Pillar Assessment

## Executive Summary

The current footprint is very small and has no obvious running compute waste:
no EC2 instances, RDS instances, ECS clusters, load balancers, Lambdas, ECR
repositories, NAT gateways, or TGWs were observed in Sandbox `us-east-2`.
However, the organization has no budgets, cost-allocation evidence, anomaly
detection, or operating model for shared network/security costs. The immediate
risk is uncontrolled future spend, not current over-provisioning.

**Risk profile:** High 1; Medium 2; Improvement opportunities 2.

AWS cost guidance recommends budgets, notifications, and policy-based controls
before enforcing cost actions. [COST02-BP05](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/cost_govern_usage_controls.html).

## Detailed findings

### COST-01 — No AWS Budgets exist in accessible accounts

1. **Risk level:** High.
2. **Description:** `describe-budgets` returned zero budget objects in
   Management, Identity, and Sandbox. No actual-spend or forecast alert was
   found.
3. **Affected resources:** All current accounts and future Security/Audit, Log
   Archive, Network, and Production accounts.
4. **Best-practice reference:** COST02-BP05, implement cost controls.
5. **Business impact:** Unexpected resource creation, data transfer, logging,
   or compromise-related spend can continue without an accountable alert.
6. **Recommendation:** Establish a small initial organization budget and
   account-level guardrails before building the landing zone.
7. **Implementation steps:** Define maintained billing recipients outside the
   repository; create a $500 monthly organization baseline; alert at 80% actual
   and 100% forecast; add Cost Anomaly Detection; test alert delivery. Begin
   with notifications, then consider budget actions only after operational
   testing.
8. **Estimated effort:** Low.
9. **Expected outcome:** Spend anomalies become visible early without blocking
   legitimate platform work.

### COST-02 — No cost-allocation or shared-cost model is evidenced

1. **Risk level:** Medium.
2. **Description:** The Organization root defines some infrastructure tags,
   but no activated cost-allocation tags, Cost Categories, CUR, tagging
   coverage report, or chargeback/showback model was found. Planned Network,
   Security, and Log Archive accounts will generate shared costs.
3. **Affected resources:** Future TGW, NAT, Network Firewall, VPC endpoints,
   CloudTrail, Config, Security Hub, GuardDuty, and workload resources.
4. **Best-practice reference:** [COST03-BP02 Add organization information to
   cost and usage](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/cost_monitor_usage_org_information.html).
5. **Business impact:** Teams cannot attribute shared platform costs or decide
   whether a networking/security architecture is economically justified.
6. **Recommendation:** Define mandatory `Application`, `Environment`, `Owner`,
   and `CostCenter` tags; activate them for billing; establish Cost Categories
   by account and workload; create a monthly ownership review.
7. **Implementation steps:** Publish tag schema and exceptions; enforce tags at
   resource creation through reviewed modules/policies; activate selected tags;
   configure cost categories and a CUR/query destination after Log Archive or
   a dedicated financial-reporting design is approved.
8. **Estimated effort:** Medium.
9. **Expected outcome:** Shared and workload costs can be assigned and optimized.

### COST-03 — Commitment strategy cannot be evaluated yet

1. **Risk level:** Medium.
2. **Description:** There is no running workload or utilization history, so
   Reserved Instances, Savings Plans, provisioned capacity, and cache/database
   reservations cannot be justified. The small control plane should remain
   pay-as-you-go.
3. **Affected resources:** Future compute, database, data transfer, and
   networking services.
4. **Best-practice reference:** Cost optimization requires usage awareness
   before commitment decisions.
5. **Business impact:** Buying commitments before stable utilization risks
   waste; delaying all analysis until scale can miss discounts when demand is
   predictable.
6. **Recommendation:** Do not buy commitments during foundation build. Review
   60-90 days of stable usage after workload launch and model steady versus
   failover capacity separately.
7. **Implementation steps:** Establish cost-per-request/user, utilization, and
   regional data-transfer metrics; forecast baseline capacity; compare on-
   demand and commitment scenarios; require finance/platform approval.
8. **Estimated effort:** Low now; Medium after workload launch.
9. **Expected outcome:** Discounts match proven demand rather than assumptions.

## Improvement opportunities

| Opportunity | Evidence | Recommendation |
|---|---|---|
| Preserve the minimal footprint. | No active Sandbox compute/data/network fleet was found; DynamoDB locks are on-demand. | Create only justified services and tear down test planes through the guarded workflow. |
| Design shared network services for transparent cost. | A dedicated Network account is planned for TGW/RAM/inspection. | Tag/allocate TGW attachments, endpoint, NAT, firewall, and data-transfer costs to consumers; do not create empty hubs in every Region. |

## Prioritized action plan

1. **0-30 days:** Budgets, anomaly detection, alternate contacts, and tag
   schema/owners.
2. **30-90 days:** Cost Categories/CUR and shared-network allocation design;
   dashboard cost per account/workload.
3. **90+ days:** Right-size from workload telemetry; purchase commitments only
   after stable utilization and failover capacity are understood.
