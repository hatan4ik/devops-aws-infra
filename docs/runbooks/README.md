# Operational runbooks

These runbooks are execution gates, not evidence that a resource already exists. They must be tailored with the approved account IDs, Regions, change ticket, on-call integrations, and owner contacts before an operator executes them. The post-deployment scripts are deliberately read-only; they are linked where they can provide objective evidence.

| Runbook | Use | Non-negotiable completion evidence |
|---|---|---|
| [Account vending](account-vending.md) | Create a new governed AWS account through Control Tower/AFT. | Account in approved OU, baseline controls/logging active, no standing credentials, approved owner access. |
| [Adding a Region](adding-region.md) | Extend a platform/environment into a second approved AWS Region. | Quotas, IPAM/TGW/DNS/data/identity checks, post-deploy tests, and a staging game day. |
| [Hybrid VPN/BGP onboarding](hybrid-vpn-bgp-onboarding.md) | Connect an on-premises routing domain to a regional TGW. | Two healthy tunnels/paths, prefix filters, isolation checks, and recorded rollback. |
| [Regional failover](regional-failover.md) | Operate a controlled application regional failover. | Health signal, traffic shift, auth/API/data validation, incident timeline, and controlled failback. |
| [Break-glass access](break-glass-access.md) | Resolve a critical incident requiring exceptional access. | Approval, MFA/session evidence, CloudTrail review, privilege removal, and post-incident review. |
| [AWS access bootstrap](bootstrap-aws-access.md) | Establish approved human access before any operational action. | IAM Identity Center session, account identity evidence, and no standing credentials. |
| [Legacy state-backend adoption](adopt-legacy-state-backend.md) | Re-address the observed bootstrap state into the canonical transitional root. | Preflight, protected state backup, active-lock check, no-resource-change plans, reviewers, and cost owner. |
| [Terraform state restore](state-restore.md) | Recover state metadata after a confirmed corruption/change incident. | Approved S3 version, rollback copy, refresh-only plan, CloudTrail, and incident review. |
| [Planned regional evacuation](regional-evacuation.md) | Withdraw a Region after workload/data migration. | Data/identity/traffic/route evidence, rollback decision, and approved decommission. |
| [Account decommission](account-decommission.md) | Retire a migrated or unused governed account. | Retention, dependency, route/DNS, state, billing, and closure evidence. |

No runbook permits changing AWS. The published root quality workflow remains credential-free; AWS delivery requires the remote-control and apply gates in the architecture and pipeline documentation.
