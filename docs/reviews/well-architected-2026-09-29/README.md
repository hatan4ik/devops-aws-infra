# AWS Well-Architected Review — Executive Summary

**Classification:** Dated assessment evidence. For current operating state and
the approved documentation flow, start at the [documentation index](../../README.md).
This assessment does not override current status or an accepted ADR.

**Assessment date:** 2026-09-29
**Scope:** AWS Organization `o-94zz9kms7u`; accessible Management
(`915507704945`), Identity delegated-admin (`749939210873`), and Sandbox
(`448871779014`) accounts; `us-east-1`, `us-east-2`, and `us-west-2`; the
`hatan4ik/devops-aws-infra` delivery repository.
**Method:** Read-only AWS CLI/API inventory, live organization and policy
inspection, and static repository review. No AWS resource, account, route,
policy, Terraform state, or GitHub setting was changed.

The Well-Architected Framework evaluates Operational Excellence, Security,
Reliability, Performance Efficiency, Cost Optimization, and Sustainability.
[AWS framework overview](https://docs.aws.amazon.com/wellarchitected/2023-10-03/framework/the-pillars-of-the-framework.html)

## Overall conclusion

**Production readiness: No.** The Organization and GitOps delivery foundation
are promising, but the current state is a control plane with no application
workload. It must not be represented as a production-ready, multi-Region
platform until the critical identity, logging, detection, account-placement,
and networking controls are implemented and evidenced.

| Pillar | High | Medium | Improvement opportunities | Assessment outcome |
|---|---:|---:|---:|---|
| [Operational Excellence](operational-excellence.md) | 1 | 2 | 2 | Delivery discipline exists; runtime operations are not yet measurable. |
| [Security](security.md) | 5 | 2 | 2 | High-risk account and detective-control gaps block production. |
| [Reliability](reliability.md) | 3 | 2 | 2 | No workload HA, DR, quota, or failover evidence exists yet. |
| [Performance Efficiency](performance-efficiency.md) | 1 | 2 | 2 | No live workload or load-test evidence; scaling design remains unvalidated. |
| [Cost Optimization](cost-optimization.md) | 1 | 2 | 2 | Very little current waste, but no budgets, allocation, or operating controls. |
| [Sustainability](sustainability.md) | 0 | 2 | 2 | Minimal current footprint; no workload efficiency baseline or KPI. |

The counts are findings, not a percentage score. A percentage would falsely
imply that workload controls were tested when no workload exists.

## Verified strengths

- AWS Organizations is enabled with all features, six approved OUs, IAM
  Identity Center, and short-lived SSO access for humans.
- There are no root access keys in the three accessible accounts.
- Management and Identity accounts have no IAM users.
- GitHub OIDC trust was found on 13 delivery roles across Management and
  Sandbox; every discovered trust policy contained both `sts.amazonaws.com`
  audience and repository-subject constraints.
- The repository has 23 delivery workflows, plan/apply/drift separation,
  guarded teardown, and seven runbooks.
- The observed state/control-plane S3 buckets are encrypted, block public
  access, are not public by bucket policy, and the versioned state buckets use
  KMS and Object Lock. The observed DynamoDB lock tables use KMS encryption and
  on-demand capacity.
- No Terraform-tagged Sandbox VPC, running EC2, ECS cluster, ECR repository,
  Cognito pool, RDS instance, Lambda function, API Gateway, load balancer,
  Transit Gateway, or Flow Log was found in `us-east-2`.

## Critical findings

| Priority | Finding | Evidence | Required outcome |
|---|---|---|---|
| P0 | Root MFA is disabled in all three accounts. | `AccountMFAEnabled=0`; Management root has no MFA and cannot be considered secured. | Enable and independently verify root MFA; establish recovery ownership. |
| P0 | A Sandbox IAM user has an active access key and no MFA. | Credential report aggregate: one IAM user, one active key, no MFA, no console password. | Eliminate/rotate the key and replace human access with IAM Identity Center or a narrowly scoped role. |
| P0 | No organization CloudTrail. | Management returned zero trails. | Create a multi-Region organization trail to a dedicated Log Archive account before workloads. |
| P0 | Detective controls are absent. | GuardDuty detector count is zero in accessible `us-east-2`; Security Hub is unsubscribed in Management; no Config aggregator. | Centralize GuardDuty, Security Hub, Config, alerting, and findings ownership in Security/Audit. |
| P1 | Existing member accounts are at the Organization root. | Both member accounts have root as parent. | Import/adopt and move them to approved OUs before relying on OU guardrails. |
| P1 | The root SCP blocks material VPC/TGW actions in `us-west-2`. | Explicit SCP deny on `ec2:DescribeVpcs` and TGW read actions; source intent differs. | Replace, test, and then detach the advanced root policy; retain a US-only boundary. |
| P1 | No budget objects or alternate contacts exist. | Budget count zero in all three accounts; Security alternate contact returns `ResourceNotFound`. | Establish organization/account budgets, alerts, Cost Anomaly Detection, and all alternate contacts. |

## Prioritized action plan

### Immediate — 0 to 14 days

1. Enable Management root MFA manually; verify it through a read-only API
   check. Decide and document the member-root access model.
2. Remove or rotate the Sandbox IAM user's active key. Do not disclose it in
   tickets, logs, repository files, or this review.
3. Set Security, Billing, and Operations alternate contacts for every account;
   use maintained group mailboxes, not an individual mailbox.
4. Approve the supplied Security/Audit and Log Archive account inputs and
   provide an explicit unique Network-account email. Do not infer an alias.
5. Approve the SCP replacement test contract; do not detach the current root
   regional policy before its replacement protects the member accounts.

### Short term — 15 to 45 days

1. Create Security/Audit, Log Archive, and Network accounts through the
   governed Organizations delivery path; move existing member accounts only
   after an import/move plan is reviewed.
2. Establish organization CloudTrail, Config aggregation, GuardDuty, Security
   Hub, security-event alerting, and immutable central log storage.
3. Create a $500 initial organization budget, 80% actual-spend alert, 100%
   forecast alert, and Cost Anomaly Detection. Confirm the notification
   distribution list outside the repository.
4. Replace the regional SCP, test `us-east-2` and `us-west-2`, and preserve
   organization-escape/managed-role controls.
5. Build the Network account IPAM/TGW hub only after the route matrix and
   on-premises overlap review are approved.

### Long term — 46 to 90+ days

1. Rebuild the Sandbox application plane through the protected workflow,
   including private networking, workload telemetry, alarms, runbooks, backup,
   and recovery tests.
2. Define SLOs and a capacity/load-test programme before any 10K-to-10M user
   claim. Record P50/P95/P99, error rate, saturation, and cost-per-request.
3. Add the `us-west-2` hub and only the justified recovery/production spokes;
   conduct regional failover and quota game days.
4. Establish Cost and Usage Reports, cost categories, allocation-tag coverage,
   sustainability KPIs, and an evidence cadence for all six pillars.

## Assessment limitations

- No application, public edge, database, cache, API, load balancer, or workload
  VPC exists in the assessed Sandbox account. Their runtime security,
  performance, availability, backup, and sustainability properties were not
  testable.
- The current root SCP denies some read calls in `us-east-1` and `us-west-2`
  for member accounts. Those access denials are themselves a material policy
  finding; Management-account inventory was used where possible.
- This review did not inspect root passwords, root recovery channels, sensitive
  contact details, secret values, CloudTrail event contents, or IAM-user names.
- No billing history, support-plan details, user geography, compliance target,
  SLO, RTO/RPO, application code, load-test result, or on-premises network
  prefix was supplied. Recommendations requiring those facts are explicitly
  gated rather than guessed.

## Evidence and supporting references

- [Current architecture overview](../../ARCHITECTURE.md)
- [Current project status](../../PROJECT-STATUS.md)
- [AWS Security Pillar — Detection](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/detection.html)
- [AWS Reliability Pillar — Service quotas](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_manage_service_limits_aware_quotas_and_constraints.html)
- [AWS Cost Optimization — Cost controls](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/cost_govern_usage_controls.html)
- [AWS Operational Excellence — Runbooks](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/ops_ready_to_support_use_runbooks.html)

## Reports

1. [Operational Excellence](operational-excellence.md)
2. [Security](security.md)
3. [Reliability](reliability.md)
4. [Performance Efficiency](performance-efficiency.md)
5. [Cost Optimization](cost-optimization.md)
6. [Sustainability](sustainability.md)
