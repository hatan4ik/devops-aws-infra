# Application, identity, and data design

## Identity and authorization

Amazon Cognito User Pools is the authentication system of record. The production pool uses the **Essentials** tier plus managed multi-Region replication (MRR) to one secondary Region, a multi-Region KMS customer-managed key, and a multi-Region OIDC issuer/custom domain configuration.

The choice is deliberately constrained by Cognito's native semantics:

- A user pool normally stores profile data in one Region. MRR adds one secondary replica with synchronized user data, credentials, and most configuration.
- The primary remains authoritative for signup, password reset, and profile writes. The active secondary can authenticate and issue tokens during failover, but cannot create users or perform all profile operations.
- Replication is eventually consistent. TOTP MFA is not supported in a secondary replica; product requirements must choose an MFA method compatible with regional failover or accept that limitation.
- A pool supports up to 40,000,000 users. The default `UserAuthentication` quota is 120 RPS per AWS account per Region and is adjustable/purchasable. The 300 RPS assumption therefore requires capacity approval in both Regions.

This is the lowest-operations AWS-native alternative to self-managed identity or custom cross-Region password replication. It produces regional resilience for authentication, not multi-primary identity writes. App clients must use the Cognito custom-domain health routing for managed login/federation, and backend/SDK clients must dynamically select the healthy regional endpoint.

Authorization has two paths:

1. Cognito-issued JWT scopes, groups, tenant IDs, and app claims are validated locally by the API for coarse authorization. API authorization never trusts a caller-supplied role header.
2. Amazon Verified Permissions (Cedar) evaluates selected high-value, resource-level decisions such as cross-tenant sharing, delegations, or administrative actions. Service-to-service access uses IAM roles, not end-user IAM identities.

Verified Permissions is not called on every API request by default. At the 10,000-RPS assumption, a decision on every request is 25.92 billion monthly decisions; at the published `$5/million` single-decision price that is about `$129,600/month`. The initial model assumes only 1% of requests need a fine-grained decision (`$1,296/month`); cache only decisions whose revocation window is documented and acceptable.

## Compute

ECS on Fargate is the default application runtime. Services run in two private subnets per Region, have a regional ALB target group, minimum healthy capacity in both AZs, target-tracking autoscaling, deployment circuit breaker, graceful shutdown, and ADOT instrumentation. Images come from ECR with vulnerability scanning and signed-image policy when selected.

Lambda is permitted for asynchronous event handlers, scheduled jobs, glue code, and lightweight request transformations. It is not the default long-lived API plane until cold-start, concurrency, VPC, streaming, and cost measurements demonstrate it meets the API SLO. EKS is rejected for the initial platform because it adds Kubernetes control-plane/add-on/operations responsibilities without a supplied workload feature requiring them.

The assumed Fargate task count is only a cost placeholder. Production cannot claim a 10,000-RPS regional capacity until an authenticated, representative load test determines CPU, memory, downstream connection, and autoscaling targets.

## Data

| Data class | Initial service | Replication and consistency | Guardrail |
|---|---|---|---|
| User profile, session metadata, idempotency, tenant settings | DynamoDB global tables, multi-Region eventual consistency (MREC). | Writes are local; asynchronous multi-active replication; conditional writes, version fields, idempotency keys, and deterministic conflict handling are mandatory. | Do not put passwords, plaintext secrets, or unbounded session blobs in DynamoDB. Monitor replication lag and backup/PITR. |
| Strongly consistent cross-Region records | DynamoDB MRSC only when a business invariant requires it and the chosen Regions are in a supported MRSC Region set. | Higher write-latency/availability trade-off is accepted explicitly. | An ADR amendment must name the invariant, Region set, and failure behavior. |
| Relational transaction data | Aurora Global Database only if the data model requires relational joins, transactional invariants, or a migration path that DynamoDB cannot meet. | Single-writer failover semantics, not assumed multi-writer. | No Aurora cluster is created in the base platform. A workload ADR must justify it. |
| Hot non-authoritative reads | ElastiCache for Redis, regional only. | Cache-aside; data loss or invalidation never violates correctness. | Sessions are not Redis-only; caches have TLS/auth and no public endpoint. |
| Immutable audit/log data | S3 in the Log Archive account. | Versioning, SSE-KMS, lifecycle, replication only where retention dictates. | Workloads cannot delete organization logs. |

## Regional failure behavior

1. Global Accelerator health checks stop routing dynamic API traffic to an unhealthy regional ALB; the healthy Region is pre-scaled according to tested N+1 capacity.
2. Cognito custom-domain/Route 53 health routing directs supported login traffic to the active secondary user pool. Product UI suppresses primary-only operations while the primary is unavailable.
3. DynamoDB global tables continue local operation in the healthy Region. Conflict/replay logic reconciles event-driven writes after recovery.
4. Route 53 private DNS, Resolver, VPC endpoints, Secrets Manager replicas where required, and observability remain independently available in both Regions.
5. Recovery requires an incident commander decision, evidence that failover conditions are met, a change record, and the documented failback sequence. It is exercised in staging before production enablement.
