# ADR 0007: Use ECS Fargate and DynamoDB global tables as the initial application plane

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

The workload must serve low-latency authenticated traffic without a stated runtime, data schema, transaction model, or operational team size. The brief prefers AWS-native services and the lowest operational burden that meets latency. Assumptions A-03, A-06, and A-10 apply.

## Options considered

1. EKS as the universal runtime with Aurora Global Database as the default datastore.
2. Lambda/API Gateway for the entire API with DynamoDB only.
3. ECS Fargate for long-running APIs, Lambda for asynchronous/spiky functions, DynamoDB global tables for profile/session data, optional Aurora Global Database and ElastiCache only when justified.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** It matches service shape to managed AWS primitives and leaves a clear exception route. |
| Network Engineer | **Approve 3.** Private Fargate services behind ALB give predictable ingress/egress controls. |
| Security Engineer | **Approve 3.** Task roles, private subnets, ECR scanning, and no node SSH reduce attack surface. |
| SRE | **Dissent: prefer 1.** EKS has mature ecosystem controls, but those do not outweigh added cluster operations without a workload need. |
| Platform/DevOps Lead | **Approve 3.** ECS Fargate minimizes platform operations and provides deliberate cost/capacity tuning. |

**Result:** 4–1 for option 3.

## Decision

Run APIs as ECS/Fargate services in private subnets across two AZs per Region, with task IAM roles, ALB health checks, autoscaling, deployment circuit breakers, and ADOT instrumentation. Use Lambda only for appropriate events/jobs. Store user profile/session/idempotency data in DynamoDB global tables MREC with conditional writes, versions, idempotency, and conflict handling. Use Aurora Global only for an explicitly documented relational invariant; use ElastiCache only as a non-authoritative regional cache.

## Consequences

- The assumed 20 production tasks per Region cost about $1,442/month across both Regions but are not proof of the 10,000-RPS objective. Load testing gates production sizing.
- MREC multi-active replication requires idempotent application behavior. MRSC or Aurora changes require a new data-consistency ADR because latency and availability characteristics change.
- Options 1 and 2 are rejected: universal EKS has unjustified operations overhead, while universal Lambda risks unmeasured latency/concurrency/VPC behavior for the primary API.
