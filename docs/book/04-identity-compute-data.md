# Chapter 4 — Identity, Compute & Data

**Status:** Stakeholder-approved 2026-09-18 · No AWS resources created  
**ADRs:** [0006](../adr/0006-identity-and-authorization.md) · [0007](../adr/0007-compute-and-data.md) · [0011](../adr/0011-cognito-mrr-provider-boundary.md)

---

## 4.1 Identity architecture

### 4.1.1 Cognito primary/secondary model

Amazon Cognito User Pools is the authentication system of record. The production pool uses the **Essentials** tier with managed multi-Region replication (MRR) to one secondary Region.

```mermaid
flowchart LR
  subgraph primary[Primary Region]
    cog_p[Cognito User Pool\nEssentials tier\nPrimary — authoritative]
    domain_p[Custom domain\nauth.example.com]
    kms_p[Multi-Region KMS CMK\nPrimary key]
  end

  subgraph secondary[Secondary Region]
    cog_s[Cognito User Pool\nMRR Secondary replica]
    domain_s[Custom domain\nhealth-routed failover]
    kms_s[Multi-Region KMS CMK\nReplica key]
  end

  cog_p -. managed replication\neventually consistent .-> cog_s
  kms_p -. key replication .-> kms_s
  domain_p --> cog_p
  domain_s --> cog_s
```

**Critical constraints:**

| Operation | Primary Region | Secondary Region (during failover) |
|---|---|---|
| User signup | ✅ Available | ❌ Suspended / redirected |
| Password reset | ✅ Available | ❌ Suspended / redirected |
| Profile writes | ✅ Available | ❌ Suspended / redirected |
| Authentication / token issuance | ✅ Available | ✅ Available |
| JWT validation (local) | ✅ Available | ✅ Available |
| TOTP MFA | ✅ Available | ❌ Not supported in secondary replica |

**MRR Terraform block:** Cognito MRR is blocked pending Terraform AWS provider support (ADR 0011). It must not be substituted with imperative CLI/console steps that create unmanaged state.

### 4.1.2 Authorization model

```mermaid
flowchart TD
  jwt[Cognito JWT\nscopes · groups · tenant ID · app claims]
  api[API Service\nECS Fargate]
  avp[Amazon Verified Permissions\nCedar policy engine]

  jwt --> api
  api --> coarse[Coarse authorization\nJWT claims — local validation\nEvery request]
  api --> fine[Fine-grained authorization\nVerified Permissions — Cedar\n~1% of requests\nCross-tenant · delegations · admin actions]
  coarse --> allow_deny[Allow / Deny]
  fine --> avp --> allow_deny
```

**Cost constraint:** At 10,000 API RPS, Verified Permissions on every request ≈ 25.92B decisions/month ≈ `$129,600/month`. The design scopes Cedar to ~1% of requests (high-value decisions only) ≈ `$1,296/month`.

### 4.1.3 Human identity — IAM Identity Center

- Federated from the organization's approved identity source
- Phishing-resistant MFA where available
- Least-privilege permission sets with short-lived sessions
- No daily IAM users or long-lived access keys
- Break-glass access is a separate, monitored, time-bound process (see [runbook](../runbooks/break-glass-access.md))

---

## 4.2 Compute architecture

### 4.2.1 ECS Fargate baseline

```mermaid
flowchart TD
  alb[Regional ALB\nPublic subnets · WAF]
  tg[Target Group\nHealth checks]
  alb --> tg

  subgraph ecs[ECS Cluster — Private subnets]
    svc[ECS Service\nDeployment circuit breaker\nGraceful shutdown\nTarget-tracking autoscaling]
    t1[Task AZ-1\n1 vCPU · 2 GiB\nADOT sidecar]
    t2[Task AZ-2\n1 vCPU · 2 GiB\nADOT sidecar]
    tN[Task AZ-N\nautoscaled]
    svc --> t1
    svc --> t2
    svc --> tN
  end

  tg --> svc
  t1 --> vpce[VPC Endpoints\nECR · DynamoDB · Secrets Manager\nCloudWatch · KMS · etc.]
  t2 --> vpce
  tN --> vpce
```

**Fargate task configuration requirements:**
- Minimum healthy capacity in both AZs
- Deployment circuit breaker with rollback enabled
- Graceful shutdown (SIGTERM handler + `stopTimeout`)
- ADOT/OpenTelemetry instrumentation for traces, metrics, and logs
- Images from ECR with vulnerability scanning; signed-image policy when selected
- No public IP on tasks; all AWS service calls via VPC endpoints

### 4.2.2 Compute decision rationale

| Option | Decision | Reason |
|---|---|---|
| ECS Fargate | **Default** | Managed control plane, per-task billing, no cluster node management |
| Lambda | Permitted for async handlers, scheduled jobs, glue code, lightweight transforms | Not default for long-lived API until cold-start/concurrency/VPC measurements meet SLO |
| EKS | **Rejected for initial platform** | Adds Kubernetes control-plane/add-on/operations responsibilities without a supplied workload feature requiring them |

---

## 4.3 Data architecture

### 4.3.1 Data service selection

| Data class | Service | Replication model | Guardrails |
|---|---|---|---|
| User profile, session metadata, idempotency, tenant settings | DynamoDB global tables | Multi-active eventual consistency (MREC); writes are local | No passwords, plaintext secrets, or unbounded blobs; monitor replication lag and PITR |
| Strongly consistent cross-Region records | DynamoDB MRSC | Higher write-latency/availability trade-off; accepted explicitly | ADR amendment required naming the invariant, Region set, and failure behavior |
| Relational transaction data | Aurora Global Database | Single-writer failover; not multi-writer | No Aurora cluster in base platform; workload ADR must justify it |
| Hot non-authoritative reads | ElastiCache for Redis (regional) | Cache-aside; data loss never violates correctness | Sessions not Redis-only; TLS/auth required; no public endpoint |
| Immutable audit/log data | S3 in Log Archive account | Versioning · SSE-KMS · lifecycle · replication where retention dictates | Workloads cannot delete organization logs |

### 4.3.2 DynamoDB global table replication

```mermaid
flowchart LR
  subgraph primary[Primary Region]
    app1[ECS Fargate]
    ddb1[(DynamoDB\nGlobal Table\nReplica)]
  end
  subgraph secondary[Secondary Region]
    app2[ECS Fargate]
    ddb2[(DynamoDB\nGlobal Table\nReplica)]
  end

  app1 -->|local write| ddb1
  app2 -->|local write| ddb2
  ddb1 <-->|async replication\nRPO ≤5 min target| ddb2
```

**Mandatory DynamoDB patterns:**
- Conditional writes and version fields on all mutable items
- Idempotency keys on all write paths
- Deterministic conflict handling documented per entity type
- PITR enabled; backup/restore tested before production
- Replication lag monitored with CloudWatch alarm at RPO threshold

---

## 4.4 Regional failure behavior

```mermaid
sequenceDiagram
  participant GA as Global Accelerator
  participant COG as Cognito Custom Domain
  participant DDB as DynamoDB Global Table
  participant R53 as Route 53 Private DNS
  participant APP as Application (Survivor Region)

  Note over GA: Regional ALB health check fails
  GA->>APP: All dynamic API traffic routed to survivor
  APP->>APP: Autoscaling to N+1 pre-scaled capacity
  COG->>COG: Health routing activates secondary pool
  Note over COG: Auth reads/tokens available\nSignup/password-reset suspended
  DDB->>DDB: Local writes continue in survivor Region
  R53->>R53: Private DNS, Resolver, VPC endpoints\nindependently available per Region
  Note over APP: Incident commander decision required\nfor failback after primary recovery
```
