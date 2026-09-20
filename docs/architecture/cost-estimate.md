# Indicative monthly cost estimate

**Currency:** USD. **Benchmark:** `us-east-2` published examples and rates, 730 hours/month. **Status:** planning estimate, not a quote or budget approval. Selected Regions, traffic volume, application benchmark, retention, data transfer, endpoint inventory, and enterprise discounts can materially change every total.

## Cost drivers and formulas

| Component | Assumption / formula | Monthly estimate |
|---|---|---:|
| Cognito Essentials + MRR, dev | 10,000 MAU: base free tier + `10,000 x $0.0045` MRR add-on. | $45 |
| Cognito Essentials + MRR, staging | 100,000 MAU: `(100,000 - 10,000) x $0.015` + `100,000 x $0.0045`. | $1,800 |
| Cognito Essentials + MRR, prod | 1,000,000 MAU: `(1,000,000 - 10,000) x $0.015` + `1,000,000 x $0.0045`. | $19,350 |
| Cognito auth quota, prod | 300 RPS target in both Regions: `2 x (300 - 120) x $20/RPS-month`. | $7,200 |
| ECS Fargate, dev | Four always-on 1-vCPU/2-GiB Linux/x86 tasks across two Regions at `$0.000011244/vCPU-second + $0.000001235/GiB-second`. | $144 |
| ECS Fargate, staging | Eight equivalent tasks. | $288 |
| ECS Fargate, prod | Forty equivalent tasks. This is a cost placeholder, not a 10,000-RPS capacity claim. | $1,442 |
| Workload VPC TGW attachments | Two regional attachments x `$0.05/hour x 730`. Data processing is excluded. | $73 per environment |
| Interface endpoints | Eight interface services x two AZs x two Regions x `$0.01/hour x 730`. S3/DynamoDB gateway endpoints are free; endpoint data processing is excluded. | $234 per environment |
| Dynamic API entry | Two ALBs at an assumed `$0.0225/hour` plus one Global Accelerator at `$0.025/hour`; ALB LCUs and Accelerator data transfer are excluded. | $51 per environment |
| WAF baseline | Two Web ACLs, three AWS-managed rules each, plus requests at `$0.60/million`: dev 10M, staging 100M, prod 1B requests. | $22 / $76 / $616 |
| KMS and observability allowance | Initial key count, metrics, logs, traces, and security events. Vended-log and archive-storage volume is excluded. | $30 / $60 / $190 |

## Transitional state backend

This is a separately governed legacy bootstrap, not part of the environment
totals below. Its real cost cannot be estimated honestly from the repository:
S3 storage/version count, Object Lock retained bytes, KMS request volume,
DynamoDB on-demand requests, and PITR backup volume have not been supplied.

| Component | Measurement and evidence | Cost owner | Monthly estimate |
|---|---|---|---:|
| Legacy state backend: S3 versioned/Object-Lock state, customer KMS key, DynamoDB lock table with PITR | First 30 days of Cost Explorer/CUR line items after an approved adoption, retained with the state-change evidence. | Platform/DevOps Lead until a named FinOps owner accepts it. | Unknown — intentionally not guessed. |

## Shared network floor

This cost is shared by all environments and is allocated equally in the environment totals below.

| Shared component | Formula | Monthly estimate |
|---|---|---:|
| Four VPN connections and their TGW VPN attachments | `4 x ($0.05 + $0.05) x 730`; excludes public IPv4 and data transfer. | $292 |
| Four shared/inspection VPC TGW attachments | `4 x $0.05 x 730`. | $146 |
| Shared endpoints | 32 endpoint ENIs x `$0.01/hour x 730`. | $234 |
| **Shared floor** | Before log, resolver, IPAM, and data charges. | **$672** |
| Allocation per environment | Shared floor / three environments. | **$224** |

## Environment totals

| Environment | Included monthly estimate | Important exclusions |
|---|---:|---|
| Dev | **$0.8k** | Data transfer, DynamoDB, S3, CloudWatch/vended logs, resolver IPs, NAT/firewall egress pack, email/SMS, ALB LCU, endpoint processing. |
| Staging | **$2.8k** | Same exclusions; staging must retain the two-Region architecture, not be a single-Region shortcut. |
| Production | **$29.4k** | Same exclusions plus workload-specific data, storage, backups, fraud/bot controls, and reserved/provisioned capacity choices. |

Production identity is the dominant known cost. If 5,000,000 users are MAU rather than merely registered, Cognito Essentials plus one MRR replica is approximately **$97,350/month** before authentication-quota, MFA email/SMS, and Plus-tier threat-protection costs. This must be a business-budget decision, not an unexamined platform default.

## Required high-fixed-cost decisions

| Item | Current benchmark | Recommendation |
|---|---:|---|
| NAT gateway per AZ | About `$0.045/hour` each in the US-East benchmark, or **$131/month** for four gateways across two AZs in two Regions, before processing/data transfer. | Do not deploy in workload VPCs. Deploy only in the approved inspection chain; reprice in the selected Region. |
| AWS Network Firewall | `$0.395/hour` per endpoint; **$1,153/month** for four endpoints before `$0.065/GB` processing. | No baseline Internet egress. If an exception requires egress, this centralized two-AZ design is mandatory. Matching NAT per-hour/processing charges can be waived in the same firewall service chain. |
| TGW VPC attachment | `$0.05/hour`, about **$36.50/month per attachment**, plus `$0.02/GB` in the published example. | Mandatory for each regional VPC attachment; use least number of VPCs consistent with account isolation. |
| VPN plus TGW attachment | `$0.05/hour + $0.05/hour`, about **$73/month per 1.25-Gbps connection**, before data transfer/public IPv4. | Four connections are assumed for regional/on-prem redundancy; validate actual throughput. |
| Global Accelerator | `$0.025/hour`, about **$18.25/month** per accelerator, plus accelerator data transfer. | Retain for production dynamic API only if latency/failover test proves Route 53 alone is insufficient. |
| Direct Connect | Two dedicated 1-Gbps ports at `$0.30/hour` are about **$438/month**, excluding provider cross-connect, DX gateway/TGW, and data-transfer charges. | A costed upgrade only after VPN cannot meet measured latency, jitter, availability, or throughput. |
| Shield Advanced | **$3,000/month per organization** plus applicable DTO; it includes portions of WAF usage. | Shield Standard is baseline. Advanced needs a documented DDoS/business-risk decision. |
| WAF fraud controls | Published examples show an account-takeover/fraud-control request charge can exceed **$8,000–$11,000/month** at tens of millions of inspected requests. | Scope bot/fraud controls to observed high-risk login/signup endpoints; do not enable globally by assumption. |

## Large variable-cost risks

- DynamoDB global-table replicated writes, storage, backup/PITR, and streams scale with actual data model. The published US-East benchmark is `$0.625/million` replicated write request units; model reads/writes/record size before approval.
- At 10,000 API RPS, Amazon Verified Permissions at every request is about 25.92B decisions/month, or `$129,600/month` at `$5/million`. The recommended 1% sensitive-action scope is about `$1,296/month`.
- CloudFront/Global Accelerator transfer, ALB LCU, TGW/VPN/interface-endpoint processing, NAT/firewall processing, CloudWatch vended logs, S3 retention, Cognito MFA messages, and third-party IdP usage are intentionally not guessed.

## Approval gate

Before any `apply`, create an AWS Pricing Calculator estimate in the chosen Regions with real request/GB/retention/task measurements; compare it to this model; set Budgets and Cost Anomaly Detection; and obtain a named budget owner approval for every item in the high-fixed-cost table.
