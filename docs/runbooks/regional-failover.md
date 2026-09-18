# Runbook: regional application failover

## Trigger and guardrails

Use for a declared regional application incident or an approved staging game day. The incident commander owns the decision to shift traffic; the platform pipeline does not fail over automatically. This runbook is for stateless API/data-plane routing and must not overstate Cognito capability: multi-Region identity failover remains blocked until ADR 0011 is resolved.

## Triage and decision

1. Open an incident/change record. Record start time, suspected failure domain, user impact, affected Regions/accounts, current Global Accelerator/ALB/WAF/DNS health, API error/latency, auth health, DynamoDB replication, queue/backlog, VPN/BGP, and security findings.
2. Exclude a global dependency, edge/WAF policy, DNS/certificate, identity, data-plane, malicious-traffic, or on-premises cause before declaring a single Region unavailable.
3. Confirm the survivor Region has approved failover capacity, healthy ALB targets, acceptable database replication/consistency state, accessible secrets/KMS/dependencies, no active blocking security finding, and a passing public synthetic.
4. Get the incident commander and service owner approval for the traffic change. For planned testing, obtain the approved maintenance window and rollback owner first.

## Controlled traffic shift

1. Mark only the affected regional API endpoint unhealthy or otherwise remove it according to the pre-approved Global Accelerator/health-check procedure. Do not make unrelated DNS, TGW, IAM, or data-schema changes during the shift.
2. Observe endpoint health and client traffic movement. Record the time to detect and time to usable survivor capacity; compare with the approved RTO.
3. Run [`verify_public_synthetics.sh`](../../tests/post_deploy/verify_public_synthetics.sh) from each approved synthetic geography and the staging AuthN/AuthZ contract from [the test plan](../../tests/post_deploy/auth-api-synthetic-contract.md).
4. Validate API success/error/latency, authorization allow/deny, trace continuity, regional data replication/conditional-write behavior, WAF behavior, log delivery, and hybrid paths where relevant. Do not run a customer-data backfill or destructive repair as part of traffic failover.
5. For Cognito, run only the documented supported flow. If MRR is not provider-backed and deployed, communicate the interim authentication limitation and do not declare identity failover success.

## Recovery and failback

1. Repair and prove the failed Region separately: health checks, capacity, data consistency, security controls, endpoint configuration, and root cause evidence must all be reviewed before reintroduction.
2. Reintroduce traffic gradually through the approved endpoint policy, observe the same SLOs, and stop on regression. Do not force clients or invalidate broadly issued tokens without an identity/security incident decision.
3. Close only after confirming steady-state routing, data health, centralized evidence, alert normalization, and current VPN/BGP state. Publish the timeline, measured RTO/RPO, residual risk, and follow-up owner.

## Evidence and abort conditions

Abort/revert the traffic change if the survivor Region cannot satisfy capacity, data consistency, security, or SLO guardrails. Retain CloudTrail, route/health, WAF/ALB, application, trace, and data evidence. A successful game day is required before any production regional-failover claim.
