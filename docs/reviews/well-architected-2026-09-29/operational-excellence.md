# Operational Excellence Pillar Assessment

## Executive Summary

The delivery control plane demonstrates good operational discipline: protected
GitHub OIDC workflows, plan/apply/drift separation, teardown safeguards, and
seven version-controlled runbooks exist. However, no application plane is
deployed, so telemetry, SLOs, alarms, incident execution, and operational KPIs
cannot be demonstrated. The operational model is promising but not yet
production-operational.

**Risk profile:** High 1; Medium 2; Improvement opportunities 2.

AWS guidance expects workload telemetry to include metrics, logs, and traces,
and expects runbooks to be exercised and kept current. [OPS04-BP02](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/ops_observability_application_telemetry.html)
and [OPS07-BP03](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/ops_ready_to_support_use_runbooks.html).

## Detailed findings

### OE-01 — No workload telemetry or business-operational baseline

1. **Risk level:** High — pre-production blocker.
2. **Description:** No live application, VPC, ECS service, API, load balancer,
   CloudWatch workload metric, log group, or alarm was found in Sandbox
   `us-east-2`. P50/P95/P99 latency, error rate, request volume, saturation,
   deployment health, and business KPIs are therefore not measurable.
3. **Affected resources:** Planned Sandbox application plane; no runtime
   resources currently exist to enumerate.
4. **Best-practice reference:** OPS04-BP02, implement application telemetry.
5. **Business impact:** A release could reach users without detectable latency,
   availability, or authorization regressions; the 10K-to-10M scaling goal has
   no baseline.
6. **Recommendation:** Make observability a release prerequisite, not a later
   enhancement. Define service SLOs, error budgets, dashboards, traces, alarm
   ownership, and a release-health check with the workload contract.
7. **Implementation steps:**
   - Define user journeys and SLOs before workload design: availability, P95
     latency, error rate, Cognito authentication success, and queue/table
     saturation where applicable.
   - Emit structured application logs with correlation/request IDs; use metrics
     and traces without storing authentication tokens or PII.
   - Provision dashboards and alarms in the same reviewed change as the
     workload; validate alarm delivery during a non-production exercise.
8. **Estimated effort:** High.
9. **Expected outcome:** Operators can detect, diagnose, and roll back a bad
   release before it becomes a broad customer incident.

### OE-02 — Incident response and recovery runbooks are not exercised

1. **Risk level:** Medium.
2. **Description:** The repository contains break-glass, state restore,
   delivery, teardown, and workload runbooks, but no evidence was supplied of
   a recent incident drill, restore test, application rollback, or regional
   failover exercise.
3. **Affected resources:** Repository runbooks; future Security/Audit,
   Log Archive, Network, and workload accounts.
4. **Best-practice reference:** OPS07-BP03, use and validate runbooks.
5. **Business impact:** A documented procedure may fail under pressure because
   permissions, dependencies, contacts, or current topology have changed.
6. **Recommendation:** Create a quarterly operational exercise calendar with
   owner, expected result, evidence location, and corrective-action tracking.
7. **Implementation steps:**
   - Run a tabletop for root-account compromise, lost OIDC access, and failed
     application deployment.
   - After the application is rebuilt, test rollback, state restore, and one
     AZ failure in Sandbox.
   - Record elapsed detection, decision, rollback, and recovery time; update
     the runbook from evidence.
8. **Estimated effort:** Medium.
9. **Expected outcome:** Repeatable response rather than improvised recovery.

### OE-03 — No organization-wide operational view or ownership model

1. **Risk level:** Medium.
2. **Description:** IAM Identity Center and GitHub OIDC exist, but there is no
   central observability account, cross-account CloudWatch view, alert-routing
   distribution list, or documented on-call ownership for future accounts.
3. **Affected resources:** Management, Identity, Sandbox, planned
   Security/Audit and Log Archive accounts.
4. **Best-practice reference:** OPS04-BP02 cross-account observability.
5. **Business impact:** Alerts may arrive in the wrong account or to no owner,
   increasing mean time to detect and recover.
6. **Recommendation:** Assign an Operations/SRE owner and establish a
   Security/Audit observability account before operating multiple accounts.
7. **Implementation steps:** Define alert severity, recipients, escalation,
   acknowledgement SLA, dashboard access, and a monthly operations review.
8. **Estimated effort:** Medium.
9. **Expected outcome:** Consistent operational ownership across accounts.

## Improvement opportunities

| Opportunity | Evidence | Next step |
|---|---|---|
| Preserve the GitOps delivery boundary. | 23 workflows; protected plan/apply/drift and guarded teardown patterns exist. | Add new roots and operational controls through the same evidence-producing path. |
| Keep runbooks as code. | Seven runbooks are version-controlled. | Add security, CloudTrail, TGW, incident, backup, and regional-failover runbooks before those capabilities are deployed. |

## Prioritized action plan

1. **0-30 days:** Define SLO/KPI and alarm requirements, owners, and incident
   exercise calendar before rebuilding a workload.
2. **30-90 days:** Deliver cross-account observability and demonstrate
   rollback/restore in Sandbox.
3. **90+ days:** Perform game days for regional failover, network isolation,
   and sustained load; use results to revise runbooks and automation.
