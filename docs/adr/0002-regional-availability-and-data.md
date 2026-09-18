# ADR 0002: Use an active-active application/data plane with native identity failover

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

The application must serve millions of authenticated users with low latency and survive a Region loss. The brief does not specify traffic geography, data residency, RTO, RPO, or a target Region; assumptions A-01 through A-07 make those explicit. Cognito identity writes have materially different multi-Region behavior from stateless application workloads.

## Options considered

1. Single Region, multi-AZ with backups.
2. Active-passive application, data, and identity in two Regions.
3. Active-active application and DynamoDB data plane, with Cognito managed multi-Region replication (MRR) primary/secondary identity semantics.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** It minimizes regional user latency and supports a regional-loss service posture without inventing multi-primary identity. |
| Network Engineer | **Dissent: prefer 2.** Active-active increases cross-Region routing and troubleshooting complexity. |
| Security Engineer | **Approve 3.** The split explicitly acknowledges that identity directory writes are not active-active. |
| SRE | **Approve 3.** Pre-warmed capacity and exercised health routing support the stated RTO better than a cold passive stack. |
| Platform/DevOps Lead | **Approve 3.** A common regional deployment contract enables identical promotion and testing. |

**Result:** 4–1 for option 3.

## Decision

Run the stateless API and DynamoDB global-table replicas active-active in two Regions, each spanning two AZs. Each Region is independently deployable and must carry the assumed 10,000 RPS during a regional loss after capacity testing.

Use Cognito Essentials with MRR for a primary user pool and one active secondary user-pool replica. Treat identity as primary/secondary for writes and as failover-capable for supported authentication. MRR replication is eventually consistent; secondary sign-up, password reset, profile update, and TOTP MFA limitations are exposed in the product contract and failover runbook.

## Consequences

- The design meets low-latency API requirements but not a promise of multi-primary identity writes; product owners must accept the Cognito secondary limitations.
- Global Accelerator/health routing and DynamoDB conflict handling are required; data invariants that cannot tolerate MREC require an MRSC or relational ADR amendment.
- MRR needs a multi-Region KMS key and adds MAU cost. Options 1 and 2 are rejected because they raise regional-latency and recovery risk beyond the stated assumptions.
