# Runbook: direct AWS Organizations account vending

## Purpose and boundary

Use this runbook to vend an approved Network, Shared Services, Log Archive,
Security/Audit, or workload account through the canonical Terraform root. It
implements [ADR 0019](../adr/0019-direct-organizations-account-vending.md): no
Control Tower, AFT, console-created account, long-lived access key, or VPN/BGP
resource is used.

The management account is the Organizations control plane only. This runbook
does not authorize moving an existing account, closing an account, changing
the management account, enabling Control Tower, or deploying workloads.

## Required reviewed inputs

Before editing `infra/active/roots/organization/global/terraform.tfvars`, record:

1. unique AWS account email and account name;
2. target OU, business owner, technical owner, cost center, data class, and
   approved Regions;
3. IPAM allocation and TGW route-domain decision for accounts that will host a
   VPC;
4. member-account baseline plan: CloudTrail/Config, GuardDuty/Security Hub,
   log archive destination, KMS/Secrets ownership, IAM Identity Center access,
   GitHub OIDC trust/policies, and break-glass procedure; and
5. budget/alert owner and service quotas.

Do not infer email aliases or CIDRs. Empty `accounts = {}` is intentional and
must remain until every item above has an approved value.

## One-time control-plane bootstrap

This is the sole local mutation in the runbook. It runs a versioned
CloudFormation template using a short-lived IAM Identity Center profile; it
does not create or move a member account.

```bash
scripts/bootstrap-management-organization-control-plane.sh \
  --profile AWS-hatan4ik-management

scripts/configure-organization-github.sh \
  --profile AWS-hatan4ik-management
```

Before any apply, configure any required reviewers on the GitHub `landing-zone`
Environment. The setup script permits only protected-branch deployments and
stores only role ARNs and backend identifiers; it cannot choose reviewers for
the organization.

## Vending procedure

1. Add only the approved account records to the `accounts` map in the root
   tfvars file. Do not modify an existing account's email.
2. Open a pull request. The Organization plan workflow must show only the
   planned OUs/SCPs/accounts. Stop if it includes an existing-account move,
   SCP detach, policy replacement, or resource outside the root.
3. Merge only after platform and security review. Dispatch **Apply Organization
   control plane** from the default branch, select `landing-zone`, and type
   `apply`.
4. Confirm the account creation request reaches `SUCCEEDED`, record account
   ID/OU/CloudTrail evidence, then deliver its member-account baseline through
   a separate root and OIDC policy. Do not put workloads into the account first.
5. Keep scheduled drift detection enabled. It reports drift and never repairs
   it automatically.

## Abort and recovery

Stop before member-account configuration if account creation, baseline, logging,
SCP attachment, or Identity Center access is incomplete. Never use
`terraform destroy` for an account: account closure has legal, billing,
retention, and root-contact consequences and requires the separate account
decommission runbook.
