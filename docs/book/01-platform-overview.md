# Chapter 1 — Platform Overview & Concept of Operations (ConOps)

**Status:** Design reference · No application-platform AWS resources created

---

## 1.1 Purpose

This platform provides a production-grade, AWS-native foundation for a low-latency application serving millions of authenticated users. It is designed to be:

- **Active-active** across two AWS Regions for stateless application traffic and DynamoDB profile/session data
- **Governed** through AWS Organizations, Control Tower, and Account Factory for Terraform (AFT)
- **Secure by default** — no Internet egress from workload subnets, no long-lived credentials, no standing human access
- **GitOps-delivered** — every infrastructure change is a reviewed pull request, OIDC-authenticated, and pipeline-gated

The platform design is documented; it is not yet deployed. This chapter is not
the current delivery authority. The current gap and its delivery order are in
[Project status](../PROJECT-STATUS.md) and the
[first delivery slice](../delivery/first-delivery-slice.md); Chapter 12 remains
supporting reference.

---

## 1.2 Concept of Operations

### 1.2.1 Normal operations

```
┌─────────────────────────────────────────────────────────────────────┐
│                        NORMAL OPERATIONS                            │
│                                                                     │
│  Developer → PR → Quality CI → Plan CI → Human Review → Apply CI   │
│                                                                     │
│  User → Route 53 → Global Accelerator → Regional ALB → ECS Fargate │
│                                       ↘                             │
│                                    CloudFront (static)              │
│                                                                     │
│  Both Regions serve live traffic simultaneously.                    │
│  DynamoDB global tables replicate writes asynchronously.            │
│  Cognito primary pool handles all identity writes.                  │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2.2 Regional failure

```
┌─────────────────────────────────────────────────────────────────────┐
│                      REGIONAL FAILURE MODE                          │
│                                                                     │
│  1. Global Accelerator health check detects unhealthy Region.       │
│  2. All dynamic API traffic routes to the surviving Region.         │
│  3. Surviving Region is pre-scaled to N+1 capacity.                 │
│  4. Cognito custom-domain health routing activates secondary pool.  │
│     ↳ Auth reads/tokens: available in secondary.                    │
│     ↳ Signup/password-reset/profile-write: suspended or redirected. │
│  5. DynamoDB global table continues local writes in survivor.       │
│  6. Incident commander declares failover; runbook executed.         │
│  7. Controlled failback after primary Region recovery is confirmed. │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2.3 Infrastructure change lifecycle

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Author  │───▶│  PR +    │───▶│  Plan +  │───▶│  Human   │───▶│  Apply   │
│  writes  │    │  Quality │    │  Cost    │    │  Gate    │    │  (OIDC)  │
│  Terraform    │  CI      │    │  Diff    │    │  (Env)   │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                  fmt/validate    OIDC plan        2 approvals     least-priv
                  tflint           Infracost        CODEOWNER       apply role
                  Checkov/Trivy    no apply         review          env-scoped
                  terraform test   artifact         required        state lock
```

---

## 1.3 Platform scope

| In scope | Out of scope |
|---|---|
| AWS Organization, OU, and account structure | Application business logic |
| Multi-Region network fabric (TGW, VPN, IPAM) | Workload container images |
| Identity (Cognito, IAM Identity Center, Verified Permissions) | Third-party SaaS integrations |
| Compute baseline (ECS Fargate) | Data migration from existing systems |
| Data layer (DynamoDB global tables, ElastiCache) | End-user device management |
| Edge (CloudFront, Global Accelerator, WAF) | On-premises infrastructure changes |
| Security controls (GuardDuty, Security Hub, CloudTrail, KMS) | DNS registrar management |
| GitOps CI/CD pipeline (GitHub Actions, OIDC, Terraform) | Cost allocation beyond platform layer |
| Observability (CloudWatch, ADOT, OAM) | |
| Operational runbooks and game-day procedures | |

---

## 1.4 Key design constraints

| Constraint | Rationale |
|---|---|
| No static AWS credentials anywhere | Eliminates the most common cloud breach vector; OIDC provides short-lived, scoped tokens |
| No Internet egress from workload subnets by default | Reduces attack surface; egress requires an explicit approved exception through the inspection VPC |
| No automatic drift remediation | A faulty plan or drift signal must not silently alter network, identity, or data controls |
| Cognito MRR blocked until Terraform provider supports it | Prevents imperative console/CLI steps from creating unmanaged infrastructure state |
| All third-party CI actions pinned to full commit SHA | Prevents supply-chain substitution attacks |
| Two-reviewer, CODEOWNER-gated PRs on all infrastructure repos | Enforces separation of duties for every infrastructure change |

---

## 1.5 Platform maturity status

| Phase | Description | Status |
|---|---|---|
| 1–2 | Requirements, threat model, initial architecture | Complete |
| 3 | Multi-account, network, identity, compute, data ADRs | Complete — stakeholder-approved |
| 4 | Repository strategy, module topology, GitHub controls | Complete — stakeholder-approved |
| 5 | Terraform module source, roots, mocked tests | Complete — locally validated |
| 6–7 | CI/CD pipeline source, runbooks, verification contracts | Complete — locally validated |
| **Next** | **Remote repository creation, OIDC roles, sandbox apply** | **Blocked — see Chapter 12** |

---

## 1.6 Stakeholder map

| Role | Concern | Key documents |
|---|---|---|
| Cloud Architect | Overall design integrity, ADR quorum | Chapters 2, 3, 9 |
| Network Engineer | TGW, VPN/BGP, IPAM, DNS | Chapter 3, ADR 0003, 0005 |
| Security Engineer | Controls, credentials, compliance | Chapter 3, ADR 0008, 0012 |
| Identity Product Owner | Cognito, Verified Permissions, MFA | Chapter 4, ADR 0006, 0011 |
| SRE | SLOs, failover, game day, runbooks | Chapter 7, Chapter 10 |
| Platform/DevOps Lead | CI/CD, module lifecycle, GitHub controls | Chapter 5, Chapter 6 |
| Finance/FinOps | Cost model, budget approval gates | Chapter 8 |
| Legal/Compliance | Data residency, retention, PII | Assumptions A-14, A-21 |
