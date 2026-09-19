# Runbook: active-active regional evacuation

## Purpose

Safely drain dynamic API traffic from a failing Region while preserving the
remaining Region as the active service path. This is an operator procedure;
the repository does not perform an automatic failover or automatic remediation.

## Architecture boundary

Per [ADR 0002](../adr/0002-regional-availability-and-data.md), both Regions
normally serve application traffic. Per [ADR 0004](../adr/0004-edge-ingress-and-egress.md),
CloudFront/WAF serves static content and Global Accelerator routes dynamic API
traffic to regional WAF-protected ALBs. Do not use the disabled root-level
CloudFront origin-group prototype as a failover procedure.

## Procedure

1. Declare the incident, capture the health evidence, and identify the failing
   Region, affected endpoint group, and expected blast radius.
2. Verify the healthy Region’s ECS capacity, ALB target health, error rate,
   latency, and Cognito/authorization quota headroom before moving traffic.
3. With the incident commander’s approval, remove or reduce the unhealthy
   Global Accelerator regional endpoint group through the approved operational
   change path. Preserve the prior configuration for rollback.
4. Verify Global Accelerator endpoint health, healthy-region ALB 5XX/latency,
   DynamoDB replication latency, and user authentication outcomes. Record the
   time and observed impact.
5. Scale the healthy regional workload only through its approved delivery path;
   do not make untracked console changes to Terraform-managed resources.

## Re-entry

1. Verify the recovered Region with synthetic tests, endpoint health, data
   replication, capacity, and security signals.
2. Review the incident and approve re-entry with a documented traffic ramp.
3. Restore the endpoint-group configuration through the approved change path
   and observe the defined SLO window before declaring recovery.

The exact Region names, endpoints, escalation contacts, and SLO thresholds are
environment-specific prerequisites and must be added only to the protected
operational runbook for a deployed environment.
