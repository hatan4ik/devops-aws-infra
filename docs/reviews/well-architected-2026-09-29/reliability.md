# Reliability Pillar Assessment

## Executive Summary

No application workload is deployed, so it has no demonstrated availability,
backup, recovery, fault isolation, or disaster-recovery behavior. The durable
Terraform control plane is more resilient than the application plane: observed
state buckets are versioned and Object Lock/KMS protected, and lock tables are
KMS-encrypted/on-demand. The required multi-account, multi-Region network
foundation does not yet exist.

**Risk profile:** High 3; Medium 2; Improvement opportunities 2.

AWS reliability guidance treats unmonitored service quotas across accounts and
Regions as high risk. [REL01-BP01](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_manage_service_limits_aware_quotas_and_constraints.html)

## Detailed findings

### REL-01 — No deployed workload has HA, backup, or recovery evidence

1. **Risk level:** High — pre-production blocker.
2. **Description:** Sandbox `us-east-2` contains no tagged VPC, ECS cluster,
   Cognito pool, ECR repository, RDS instance, Lambda, API Gateway, load
   balancer, or TGW. No workload database backup, multi-AZ configuration,
   recovery procedure, RTO/RPO, or restore evidence exists.
3. **Affected resources:** Planned Sandbox and future Production workloads.
4. **Best-practice reference:** Reliability design for recovery and fault
   isolation.
5. **Business impact:** Availability and data-loss claims cannot be made;
   recovery capability would be discovered during an outage.
6. **Recommendation:** Define workload-specific RTO/RPO, data classification,
   backup, replication, restore, and failure-mode requirements before selecting
   compute/data services.
7. **Implementation steps:** For each stateful component, document source of
   truth, restore target, backup frequency/retention, encryption key recovery,
   acceptable data loss, restore test cadence, and owner. Require a successful
   restore test before production promotion.
8. **Estimated effort:** High.
9. **Expected outcome:** A verifiable recovery design rather than assumed HA.

### REL-02 — Multi-Region and network resilience are not implementable under current SCP state

1. **Risk level:** High.
2. **Description:** No TGW exists in accessible accounts/US Regions. The
   current root advanced regional SCP explicitly denies VPC/TGW read actions in
   `us-west-2`, even though it is the intended future secondary US Region.
3. **Affected resources:** Root policy `p-emzb3prn`; future Network account,
   TGW hubs, VPC attachments, and cross-Region recovery path.
4. **Best-practice reference:** [REL01-BP02 Manage service quotas across
   accounts and Regions](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_manage_service_limits_limits_considered.html).
5. **Business impact:** A secondary Region cannot be built or tested; a future
   failover design would have unproven routes and account/Region constraints.
6. **Recommendation:** Establish a Network account, US-only SCP replacement,
   IPAM allocation, per-Region TGW route domain, and failover test plan before
   claiming regional resilience.
7. **Implementation steps:** Replace/test the SCP first; create `us-east-2`
   primary Network hub; attach only approved spokes; define static inter-Region
   peer routes; create `us-west-2` only after quotas and route policy are
   verified there. Do not build an unused TGW mesh.
8. **Estimated effort:** High.
9. **Expected outcome:** A testable regional recovery path with explicit
   traffic isolation.

### REL-03 — No quota inventory, thresholds, or increase workflow

1. **Risk level:** High for the intended scale.
2. **Description:** No quota dashboard, alert, request template, or secondary-
   Region parity evidence was found. This is especially relevant for ECS/Fargate,
   VPC/TGW attachments, NAT/IPs, Cognito, DynamoDB, CloudWatch, and service API
   rates when scaling from 10K toward millions of users.
3. **Affected resources:** All current and future accounts/Regions.
4. **Best-practice reference:** REL01-BP01 and REL01-BP02.
5. **Business impact:** Scale events, recovery, or failover can fail due to
   account- or Region-specific quotas even when application code is correct.
6. **Recommendation:** Establish a quota catalogue and preflight gate before
   each environment/Region rollout.
7. **Implementation steps:** Identify service dependencies from the approved
   workload design; record required steady-state and failover capacity; query
   quotas in every relevant account/Region; set alerts at 80/90%; request
   increases before load testing and re-verify after approval.
8. **Estimated effort:** Medium.
9. **Expected outcome:** Capacity failures become planned work, not incidents.

### REL-04 — Central configuration inventory is incomplete

1. **Risk level:** Medium.
2. **Description:** Management `us-east-1` has one Config recorder/delivery
   channel, but it excludes IAM resource types and no organization Config
   aggregator exists. Identity and Sandbox have no observed recorder in
   `us-east-2`.
3. **Affected resources:** All Organization accounts and future network/
   workload resources.
4. **Best-practice reference:** Configuration history and cross-account
   operational visibility.
5. **Business impact:** Resource changes and compliance drift may be invisible
   during recovery investigation or post-incident review.
6. **Recommendation:** Create a Security/Audit-owned Config aggregator and
   define a recorder/recording scope appropriate to each Region/account.
7. **Implementation steps:** Decide how global IAM resource recording is
   handled once, enable approved recorders, aggregate findings centrally, and
   validate account/Region onboarding with a known resource change.
8. **Estimated effort:** Medium.
9. **Expected outcome:** Reliable cross-account configuration evidence.

### REL-05 — Root-account recovery ownership is unverified

1. **Risk level:** Medium.
2. **Description:** Root MFA is disabled and account alternate contacts are
   absent; root password/recovery-channel ownership was intentionally not
   inspected. Management account recovery is therefore a single-point-of-
   failure risk.
3. **Affected resources:** All account root identities, especially Management.
4. **Best-practice reference:** AWS root-user best practices.
5. **Business impact:** Loss of the only recovery path can delay critical
   organization-wide recovery.
6. **Recommendation:** Use a documented multi-person recovery process,
   maintained group email, current contacts, and multiple registered root MFA
   devices where policy permits.
7. **Implementation steps:** Update contacts, record custody/recovery roles in
   a protected operator system, enable MFA, perform a tabletop recovery
   exercise without changing credentials, and review quarterly.
8. **Estimated effort:** Low.
9. **Expected outcome:** Reduced account-recovery single point of failure.

## Improvement opportunities

| Opportunity | Evidence | Next step |
|---|---|---|
| Terraform control-plane state is recoverable. | Observed state buckets are encrypted/versioned/Object-Lock protected; DynamoDB lock tables are KMS/on-demand. | Test the documented state-restore procedure and protect access to state snapshots. |
| Delivery pipeline supports ordered reconstruction. | Network → platform → workload order and guarded teardown are documented. | Convert it into a recovery test with an approved non-production target. |

## Prioritized action plan

1. **0-30 days:** Root recovery/MFA, SCP replacement design, quota catalogue,
   and RTO/RPO decisions.
2. **30-90 days:** Network account/TGW primary hub, Config aggregation, backup
   standards, and Sandbox rebuild with restore evidence.
3. **90+ days:** Secondary Region, inter-Region peer/failover, regional quota
   parity, and scheduled game days.
