# Chapter 12 — Pre-Deployment Checklist

**Status:** All items OPEN — no AWS infrastructure has been created  
**Source:** [docs/architecture/external-verification.md](../architecture/external-verification.md)

> No AWS infrastructure apply may start until a change record contains: selected Region pairs; all items below completed; named cost/security/architecture approvers; Terraform plan; policy/security scan; cost diff; account IDs; approved CIDR/ASN allocation; and a rollback/stop condition.

---

## 12.1 Blocking inputs — must be resolved before any apply

### Regions and data residency

| Item | Status | Owner |
|---|---|---|
| User geography and latency tests completed | ⬜ OPEN | Product, architecture |
| Regulatory/data-residency requirements confirmed | ⬜ OPEN | Legal, compliance |
| Cognito MRR availability confirmed in both chosen Regions | ⬜ OPEN | Architecture |
| AZ capacity and disaster-recovery Region separation confirmed | ⬜ OPEN | Architecture |

### Identity

| Item | Status | Owner |
|---|---|---|
| Cognito Essentials vs. Plus feature requirements confirmed | ⬜ OPEN | Identity product owner |
| MRR eligibility in both chosen Regions confirmed | ⬜ OPEN | Identity product owner |
| One-secondary MRR limit accepted | ⬜ OPEN | Identity product owner |
| MFA/federation behavior during failover documented and accepted | ⬜ OPEN | Identity product owner |
| 300 RPS auth quota approved and purchased in each Region | ⬜ OPEN | Identity product owner |
| Actual MAU budget approved | ⬜ OPEN | Finance, identity product owner |
| Email/SMS sender quotas confirmed | ⬜ OPEN | Identity product owner |
| Custom-domain certificate ownership confirmed | ⬜ OPEN | Network/platform |

### Workload capacity

| Item | Status | Owner |
|---|---|---|
| API endpoints, real p95/p99, request/response sizes documented | ⬜ OPEN | Application/SRE |
| Fargate load test completed; scale-to-zero/steady-state needs confirmed | ⬜ OPEN | Application/SRE |
| Connection patterns and dependency limits documented | ⬜ OPEN | Application/SRE |

### Data

| Item | Status | Owner |
|---|---|---|
| Data classification and PII location confirmed | ⬜ OPEN | Product/data/security |
| DynamoDB read/write/storage/stream rates estimated and approved | ⬜ OPEN | Product/data |
| RPO confirmed and backup/restore requirements documented | ⬜ OPEN | Product/data/security |
| KMS key policy, pending-deletion period, and Object Lock mode approved | ⬜ OPEN | Security, legal/compliance |

### Enterprise network

| Item | Status | Owner |
|---|---|---|
| Approved AWS CIDR pool confirmed (replaces `10.128.0.0/9` placeholder) | ⬜ OPEN | Network team |
| All existing on-premises CIDRs and ASN plan confirmed — no overlaps | ⬜ OPEN | Network team |
| Two independent customer-gateway devices/public IPs per Region confirmed | ⬜ OPEN | Network team |
| BGP capability, MTU/MSS, prefix-filter policy confirmed | ⬜ OPEN | Network team |
| Bandwidth/jitter/latency requirements confirmed | ⬜ OPEN | Network team |

### AWS Organization

| Item | Status | Owner |
|---|---|---|
| Management account status and Control Tower availability confirmed | ⬜ OPEN | Cloud platform |
| Existing accounts/OUs, SCPs, and delegated-admin conflicts reviewed | ⬜ OPEN | Cloud platform/security |
| IAM Identity Center identity source confirmed | ⬜ OPEN | Cloud platform/identity |
| Existing logging/security services reviewed for conflicts | ⬜ OPEN | Security |

### Security and compliance

| Item | Status | Owner |
|---|---|---|
| Required compliance frameworks confirmed | ⬜ OPEN | Security/compliance |
| Retention/legal hold requirements confirmed | ⬜ OPEN | Legal/compliance |
| Break-glass process approved | ⬜ OPEN | Security |
| SIEM/on-call integration target confirmed | ⬜ OPEN | Security/SRE |
| WAF bot/fraud requirements scoped | ⬜ OPEN | Security |
| Shield Advanced risk decision made | ⬜ OPEN | Finance/security |

### DNS and certificates

| Item | Status | Owner |
|---|---|---|
| Registered domains and public/private zone ownership confirmed | ⬜ OPEN | Network/platform |
| ACM certificate validation method confirmed | ⬜ OPEN | Network/platform |
| Route 53 Resolver/on-premises DNS authority and forwarding rules confirmed | ⬜ OPEN | Network/platform |

### CI/CD

| Item | Status | Owner |
|---|---|---|
| GitHub organization slug confirmed (replaces `<org>` placeholder) | ⬜ OPEN | Platform/DevOps |
| GitHub plan capabilities confirmed (rulesets, environments, OIDC) | ⬜ OPEN | Platform/DevOps |
| Approved reusable workflow source and CODEOWNERS confirmed | ⬜ OPEN | Platform/DevOps |
| AWS OIDC role boundaries designed and reviewed | ⬜ OPEN | Platform/DevOps, security |
| Pipeline repository created with required controls | ⬜ OPEN | Platform/DevOps |

### FinOps

| Item | Status | Owner |
|---|---|---|
| Monthly/annual cost ceiling approved | ⬜ OPEN | Finance/product |
| AWS Pricing Calculator estimate completed in chosen Regions | ⬜ OPEN | Finance/architecture |
| Budget owners named for all high-fixed-cost items | ⬜ OPEN | Finance |
| AWS Budgets and Cost Anomaly Detection configured | ⬜ OPEN | Finance/platform |
| Discount/EDP status confirmed | ⬜ OPEN | Finance |

---

## 12.2 Hard blockers — cannot be worked around

| Blocker | ADR | Resolution path |
|---|---|---|
| Cognito MRR not deployable via Terraform | [ADR 0011](../adr/0011-cognito-mrr-provider-boundary.md) | Wait for Terraform AWS provider support; do not substitute CLI/console steps |
| No approved platform accounts, Regions, CIDRs, ASNs, IPAM pools, VPN customer gateways, DNS/certificates, identity roles, service quotas, data model, or application image supplied | All ADRs | Complete external verification checklist above. The separate [legacy state bootstrap](../architecture/legacy-state-bootstrap.md) must be adopted or retired before it can be treated as an approved backend. |
| No Terraform backend configuration, root-specific AWS role policy, plan/apply caller, or environment-scoped backend secret exists | [ADR 0012](../adr/0012-oidc-gated-terraform-delivery.md), [ADR 0017](../adr/0017-github-oidc-bootstrap-proof.md) | Protected environments and a permissionless sandbox OIDC proof exist; add root-specific controls and verify a sandbox plan before any apply |
| No live network/security/authentication/failover assertion has run | [ADR 0013](../adr/0013-layered-verification-no-automatic-fault-injection.md) | Complete staging game day (Chapter 7, section 7.5) |

---

## 12.3 Pre-apply evidence package

The change record for the first apply must contain:

- [ ] Selected Region pair
- [ ] All items in section 12.1 marked complete with named approver
- [ ] Named cost approver, security approver, and architecture approver
- [ ] Terraform plan output (non-secret, reviewed artifact)
- [ ] Checkov + Trivy scan results (zero HIGH/CRITICAL or approved suppressions)
- [ ] Infracost cost diff reviewed and approved
- [ ] Account IDs for all target accounts
- [ ] Approved CIDR/ASN allocation from enterprise IPAM
- [ ] Rollback/stop condition documented
- [ ] Staging game day evidence (before production apply)
