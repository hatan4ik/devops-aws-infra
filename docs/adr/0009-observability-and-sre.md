# ADR 0009: Centralize observability access and retain security evidence independently

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

The platform needs SLOs, low-latency diagnosis, security alert routing, cross-account visibility, retention, regional-failover procedures, and game-day evidence. Per-account dashboards alone make a regional incident slower to diagnose. Assumptions A-04 through A-06 apply.

## Options considered

1. Each workload account operates its own logs, metrics, traces, alerts, and runbooks.
2. A third-party observability vendor as the primary platform with AWS logs exported everywhere.
3. CloudWatch, ADOT/X-Ray-compatible traces, Observability Access Manager, Security Hub/GuardDuty aggregation, and independent Log Archive retention in central accounts.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** Central read access without central workload ownership preserves account isolation. |
| Network Engineer | **Approve 3.** VPN/TGW/Resolver/flow evidence is visible alongside application symptoms. |
| Security Engineer | **Approve 3.** Security aggregation and immutable archive are independent of workload operators. |
| SRE | **Approve 3.** Error budgets, regional synthetic checks, and failover signals have one operational view. |
| Platform/DevOps Lead | **Dissent: prefer 2.** Existing vendor tooling may offer richer analysis, but no enterprise contract or data-export requirement is given. |

**Result:** 4–1 for option 3.

## Decision

Use CloudWatch as the native metrics/logs/alarms baseline; ADOT/OpenTelemetry plus X-Ray-compatible tracing for application paths; Observability Access Manager for cross-account observation; and Security/Audit and Log Archive accounts for security aggregation and independent retention. Establish API/auth, replication, VPN/BGP, security-finding, and cost alerts. Store runbooks and game-day evidence in the platform documentation repository.

## Consequences

- Logging/metric volume and retention are variable costs; applications must use structured logs, sampling, cardinality limits, and PII redaction.
- Every workload can still own its dashboards/SLOs, but central responders have read-only cross-account incident visibility.
- Options 1 and 2 are rejected: siloed evidence impedes regional recovery; a vendor-first platform adds cost and governance before a demonstrated requirement.
