# Chapter 8 — Cost Model & FinOps

**Status:** Planning estimate — not a quote or budget approval  
**Benchmark:** `us-east-1` published rates · 730 hours/month  
**Source:** [docs/architecture/cost-estimate.md](../architecture/cost-estimate.md)

> Selected Regions, traffic volume, application benchmark, retention, data transfer, endpoint inventory, and enterprise discounts can materially change every total. Use the [AWS Pricing Calculator](https://calculator.aws) with real measurements before any apply.

---

## 8.1 Environment cost summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INDICATIVE MONTHLY TOTALS                        │
│                                                                     │
│   Dev         ~$0.8k/month                                          │
│   Staging     ~$2.8k/month                                          │
│   Production  ~$29.4k/month  ← identity is the dominant cost       │
│                                                                     │
│   Shared network floor: ~$672/month (allocated ~$224/environment)   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8.2 Component cost breakdown

| Component | Dev | Staging | Production |
|---|---:|---:|---:|
| Cognito Essentials + MRR | $45 | $1,800 | $19,350 |
| Cognito auth quota (300 RPS × 2 Regions) | — | — | $7,200 |
| ECS Fargate (4/8/40 tasks across 2 Regions) | $144 | $288 | $1,442 |
| TGW VPC attachments (2 per env) | $73 | $73 | $73 |
| Interface endpoints (8 svc × 2 AZ × 2 Region) | $234 | $234 | $234 |
| ALB × 2 + Global Accelerator | $51 | $51 | $51 |
| WAF (web ACLs + managed rules + requests) | $22 | $76 | $616 |
| KMS + observability allowance | $30 | $60 | $190 |
| Shared network floor allocation | $224 | $224 | $224 |
| **Subtotal** | **~$823** | **~$2,806** | **~$29,380** |

**Excluded from all totals:** Data transfer · DynamoDB (reads/writes/storage/streams/PITR) · S3 · CloudWatch vended logs · Route 53 Resolver IPs · NAT/firewall egress · email/SMS · ALB LCU · endpoint data processing · workload-specific data/storage/backups · reserved/provisioned capacity choices.

---

## 8.3 Shared network floor

| Component | Formula | Monthly |
|---|---|---:|
| 4 VPN connections + TGW VPN attachments | `4 × ($0.05 + $0.05) × 730` | $292 |
| 4 shared/inspection VPC TGW attachments | `4 × $0.05 × 730` | $146 |
| Shared endpoint ENIs (32) | `32 × $0.01 × 730` | $234 |
| **Shared floor** | Before log, Resolver, IPAM, data charges | **$672** |
| Per-environment allocation | Shared floor ÷ 3 | **$224** |

---

## 8.4 High-fixed-cost decision gates

These items require explicit budget approval before deployment. Do not deploy by assumption.

| Item | Benchmark | Recommendation |
|---|---:|---|
| NAT gateway (per AZ) | ~$131/month for 4 gateways across 2 AZs × 2 Regions | Deploy only in approved inspection chain; not in workload VPCs |
| AWS Network Firewall | ~$1,153/month for 4 endpoints before `$0.065/GB` processing | No baseline Internet egress; mandatory only after approved egress exception |
| TGW VPC attachment | ~$36.50/month per attachment + `$0.02/GB` | Mandatory per regional VPC; minimize VPC count consistent with account isolation |
| VPN + TGW attachment | ~$73/month per 1.25-Gbps connection | 4 connections assumed for regional/on-prem redundancy; validate actual throughput |
| Global Accelerator | ~$18.25/month + accelerator data transfer | Retain for production dynamic API only if latency/failover test proves Route 53 alone is insufficient |
| Direct Connect (1 Gbps × 2) | ~$438/month before provider cross-connect, DX gateway, and data transfer | Costed upgrade only after VPN cannot meet measured latency/jitter/availability/throughput |
| Shield Advanced | $3,000/month per organization + applicable DTO | Shield Standard is baseline; Advanced needs documented DDoS/business-risk decision |
| WAF fraud/bot controls | $8,000–$11,000+/month at tens of millions of inspected requests | Scope to observed high-risk login/signup endpoints only; do not enable globally |

---

## 8.5 Large variable-cost risks

| Risk | Detail |
|---|---|
| Cognito at scale | 5M MAU (not just registered) ≈ **$97,350/month** for Essentials + 1 MRR replica before auth-quota, MFA email/SMS, and Plus-tier threat-protection costs |
| DynamoDB global tables | Replicated write RUs, storage, PITR, and streams scale with actual data model; benchmark is `$0.625/million` replicated write RUs |
| Verified Permissions at full scale | 10,000 RPS × every request ≈ 25.92B decisions/month ≈ **$129,600/month**; design scopes to ~1% of requests ≈ **$1,296/month** |
| CloudFront/GA transfer | Not estimated; depends on content size, geography, and cache hit rate |
| CloudWatch vended logs | Not estimated; depends on log verbosity, retention, and query volume |

---

## 8.6 FinOps approval gate

Before any `terraform apply`:

1. Create an AWS Pricing Calculator estimate in the chosen Regions with real request/GB/retention/task measurements
2. Compare to this model; document variances
3. Set AWS Budgets and Cost Anomaly Detection with named budget owners
4. Obtain named approval for every item in the high-fixed-cost table (section 8.4)
5. Confirm allocation tags, chargeback model, and discount/EDP status

No apply may proceed without a named cost approver on record.
