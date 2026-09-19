# ADR 0001: Account Structure and Landing Zone

## Status
Superseded by [ADR 0014](0014-canonical-architecture-and-iac-boundary.md)

> Historical record only. The active account-vending decision is
> [ADR 0001: Control Tower and Account Factory for Terraform](0001-control-tower-account-vending.md).

## Context
We need to establish a multi-account AWS environment. We require a Management, Security, Log Archive, Shared Services/Network, Identity (IAM Identity Center), and per-workload accounts for dev, staging, and prod. We need to decide whether to use AWS Control Tower or build a custom AWS Organizations setup with custom SCPs.

## Options Considered
1. **AWS Control Tower**: AWS-managed landing zone providing pre-configured guardrails, Account Factory, and baseline integrations.
2. **Custom AWS Organizations + Custom SCPs**: Using Terraform to manage Organizations, OUs, SCPs, and account vending entirely from scratch.
3. **AWS Landing Zone (Legacy)**: Deprecated, not considered.

## Decision
**Custom AWS Organizations + Custom SCPs via Terraform**

We will implement a custom Organizations structure managed via Terraform. 
- The Account Vending process will be automated via GitOps (Terraform).
- Standard SCP baselines (deny root, deny disabling security services, region restrict, require encryption) will be managed as code.

## Consequences
* **Positive**: Complete flexibility and adherence to the "Everything as Code" and SOLID principles. No undocumented magic or Control Tower drift.
* **Negative**: Higher initial engineering effort to build the account vending machine and validate SCPs.

## Dissenting Opinions
* *SRE Reviewer*: Preferred Control Tower for out-of-the-box Account Factory and compliance dashboards.
* *Resolution*: The Cloud Architect and DevOps Lead overrode this, noting that Control Tower's Terraform integration (AFT) introduces significant operational complexity, and native Terraform `aws_organizations_account` is cleaner for GitOps.
