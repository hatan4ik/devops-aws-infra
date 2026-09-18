# External verification checklist

These items cannot be inferred safely from the brief or local references. They are blocking inputs to production implementation.

| Area | Required verification | Owner |
|---|---|---|
| Regions and data | User geography, latency tests, regulatory/data-residency needs, service/MRR availability, AZ capacity, and disaster-recovery region separation. | Product, legal, architecture. |
| Identity | Cognito Essentials/Plus feature need, MRR eligibility in both Regions, one-secondary limit acceptance, MFA/federation behavior during failover, 300-RPS quota in each Region, actual MAU budget, email/SMS sender quotas, and custom-domain certificate ownership. | Identity product owner. |
| Workload capacity | API endpoints, real p95/p99, request/response sizes, connection patterns, auth/authorization frequency, Fargate load test, scale-to-zero/steady-state needs, and dependency limits. | Application/SRE. |
| Data | Data classification, profile/session schema, PII location, consistency invariants, expected DynamoDB read/write/storage/stream rates, RPO, backup/restore requirements, relational need, cache use, and KMS key policy. | Product/data/security. |
| Enterprise network | Approved AWS CIDR pool, all existing prefixes, on-premises CIDRs and ASN plan, two independent customer-gateway devices/public IPs, BGP capability, MTU/MSS, prefix-filter policy, bandwidth/jitter/latency, and Direct Connect locations/providers. | Network team. |
| Organization | AWS Organization management account status, Control Tower region and landing-zone availability, current accounts/OUs, existing SCPs, delegated-admin conflicts, Identity Center identity source, billing payer, and existing logging/security services. | Cloud platform/security. |
| Security/compliance | Required frameworks, retention/legal hold, acceptable break-glass process, encryption standards, vulnerability SLA, SIEM/on-call integration, WAF bot/fraud requirements, Macie PII scope, and Shield Advanced risk decision. | Security/compliance. |
| DNS/certificates | Registered domains, public/private zone ownership, Resolver/on-prem DNS authority, DNS forwarding rules, ACM validation, and health-check ownership. | Network/platform. |
| CI/CD | GitHub organization/repository ownership, approved reusable workflow source, environment approvers, CODEOWNERS, signing policy, AWS OIDC role boundaries, external scanner licenses, and Infracost billing integration. | Platform/DevOps. |
| FinOps | Monthly/annual cost ceiling, allocation tags, discount/EDP status, chargeback model, budget owners, and approval for Network Firewall, VPN, TGW, Global Accelerator, Direct Connect, Shield Advanced, MRR, and Cognito quota add-ons. | Finance/product. |

## Pre-apply evidence package

No AWS infrastructure apply may start until a change record contains: selected Region pairs; completed items above; named cost/security/architecture approvers; Terraform plan; policy/security scan; cost diff; account IDs; approved CIDR/ASN allocation; and a rollback/stop condition. Local design, Terraform source, workflow source, and runbook work do not satisfy these live-environment prerequisites.
