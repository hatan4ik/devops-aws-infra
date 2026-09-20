# Architecture assumptions

These assumptions are design inputs, not confirmed requirements. Every
numerical value below must be replaced by workload measurements, a quota check,
or a business decision before an implementation is approved.

| ID | Assumption | Design use | Validation required |
|---|---|---|---|
| A-01 | The target has **5,000,000 registered users**, **1,000,000 monthly active users (MAU)**, and **250,000 peak concurrent sessions**. | Sizes the initial Cognito and cost model. | Product analytics and growth forecast. |
| A-02 | Peak interactive authentication demand is **300 UserAuthentication RPS per Region**, with either Region able to accept that rate during failover. | Cognito quota planning and regional failover capacity. | Load test including MFA/challenge rounds; Cognito quota purchase/approval. |
| A-03 | Peak API demand is **10,000 RPS globally** and either Region must be able to carry **10,000 RPS** after a regional loss. | Active-active API, data, and autoscaling design. | API payload, endpoint mix, p95/p99 service-time, and load test. |
| A-04 | Regional authentication service latency target is p50 **<=250 ms** and p99 **<=600 ms**; regional API service latency target is p50 **<=100 ms** and p99 **<=250 ms**. Measurements exclude end-user last-mile Internet latency and third-party IdP latency. | SLOs and acceptance tests. | Synthetic tests from user geographies and trace data. |
| A-05 | API availability SLO is **99.99%** per calendar month. The authentication journey SLO is **99.9%**, no higher than the selected Cognito tier's published service commitment. | Error budget, alerting, and availability design. | Contract/SLA review and product owner approval. |
| A-06 | A full regional application failover has RTO **<=60 minutes**. DynamoDB profile/session recovery target is RPO **<=5 minutes**; audit logs have RPO **<=24 hours**. | Health checks, replication monitoring, backups, and game-day criteria. | Data classification and business continuity approval. |
| A-07 | Named AWS Regions in public price examples and diagrams are **benchmarks only**, not chosen deployment locations. | Gives a consistent basis for illustrative cost and architecture discussion without selecting a Region. | User geography, latency tests, service availability, data residency, and on-premises proximity. |
| A-08 | Each Region uses **two Availability Zones**, a separate VPC per workload account, and no direct workload-to-Internet route. | AZ resilience and network isolation baseline. | Regional AZ and service capacity check. |
| A-09 | The first workload consumes **eight interface endpoint services per workload VPC**, deployed in two AZs, plus S3 and DynamoDB gateway endpoints where applicable. | Conservative PrivateLink fixed-cost model. | Exact service dependency inventory; endpoint support by Region. |
| A-10 | The cost model starts with **two 1 vCPU / 2 GiB ECS Fargate tasks per Region in dev**, **four per Region in staging**, and **twenty per Region in production**. | Illustrative steady-state compute cost only. It is not proof of 10,000 RPS capacity. | Application benchmark and autoscaling/load test. |
| A-11 | One workload account exists per environment (`dev`, `staging`, `prod`) and the shared platform costs are allocated evenly across the three environments. | Initial account and cost model. | Portfolio/workload-account plan. |
| A-12 | Each Region has two independent on-premises customer-gateway endpoints and two 1.25 Gbps Site-to-Site VPN connections to the TGW; Direct Connect is not initially deployed. | VPN/BGP redundancy and fixed-cost model. | On-premises router capability, public IPs, ASN ownership, prefix list, bandwidth, and latency demand. |
| A-13 | The address range `10.128.0.0/9` is available exclusively for AWS IPAM allocation. | Placeholder for non-overlapping account/Region CIDRs. | Enterprise IPAM and on-premises route-conflict review. |
| A-14 | No data-residency, regulated-data, external IdP, SMS, or compliance requirement has been supplied. | Keeps the architecture region-neutral and treats compliance as a blocker. | Legal/compliance and identity-product owners. |
| A-15 | AWS Network Firewall, NAT gateway, Shield Advanced, Direct Connect, and Global Accelerator are paid services requiring explicit budget acceptance. | Prevents an unexamined fixed-cost commitment. | Finance owner and AWS Pricing Calculator estimate. |
| A-16 | The eventual GitHub organization slug is not yet supplied. It will be lowercase and hyphenated, and is represented as `<org>` in repository names. | Makes the Phase 4 naming standard unambiguous without inventing an organization name. | GitHub organization owner confirmation. |
| A-17 | A protected `main` branch will require two approving reviews, including a matching CODEOWNER review; approval is dismissed on code changes and the most recent code push needs an independent approval. | Provides a baseline separation-of-duties control for infrastructure changes. | Security and platform owners must confirm it fits their GitHub plan and operating model. |
| A-18 | A composition module stays in its owning live-configuration repository until it has at least two production consumers or a demonstrably separate release and ownership lifecycle. | Prevents premature module repositories while preserving a measurable extraction threshold. | Platform module-maintainer review before extraction. |
| A-19 | The eventual GitHub organization can use private-repository rulesets, CODEOWNERS, deployment environments, signed-commit enforcement, and GitHub Actions OIDC. | Makes the proposed repository control profile implementable. | GitHub plan, enterprise policy, team slugs, and organization administrator confirmation. |
| A-20 | Terraform CLI **1.7.5** is pinned for developers and CI; reusable modules require AWS provider `>= 6.35.0, < 7.0.0`, with committed multi-platform dependency locks. | Enables provider-mocked `terraform test` and controlled provider upgrades. | CI runner image and dependency-lock review. |
| A-21 | Final platform KMS deletion periods, state noncurrent-version retention, Object Lock policy, and lock-table retirement are organization retention decisions. The observed legacy bootstrap is mirrored only to permit a separately approved adoption. | Prevents retention policy from being silently invented during platform hardening. | Security, legal/compliance, FinOps, and break-glass process owner approval. |

## Explicit non-assumptions

- A target Region, the organization name, AWS account IDs, public DNS names,
  CIDRs, ASNs, customer-gateway IPs, and certificates are intentionally not
  invented.
- No target workload has yet demonstrated its container, Lambda,
  relational-data, external-egress, or fine-grained-authorization requirements.
- No AWS quota, service availability, compliance certification, or price is
  treated as final until it is revalidated in the chosen account and Region.
- No Terraform plan is valid until target Regions, account IDs, IPAM pools, KMS
  keys, retention policy, BGP details, OIDC subjects, and workload inputs are
  approved. `region-a` and `region-b` are source-layout placeholders, never AWS
  deployment targets.
