# Runbook: account vending
# Runbook: Account Vending

## Trigger and scope
## Purpose
Automated procedure for provisioning a new AWS account under the target Organizational Unit (OU).

Use this runbook only for an approved new platform, security, shared-service, network, or workload account. The management account is never a routine deployment target. Account creation is an external AWS mutation and requires the separate remote/apply authorization, an approved change record, and the Control Tower/AFT owner.
## Prerequisites
- Identity Center (SSO) permissions for the root Management Account.
- Access to the `ses-aws-platform-roots/org` repository.

## Preflight
## Procedure
1. Open the `ses-aws-platform-roots` repository.
2. Navigate to `org/accounts.tf`.
3. Add a new `aws_organizations_account` resource (or append to the local map if using a map-driven approach):
   ```hcl
   module "new_account" {
     source = "../../modules/aws-account-vending"
     email  = "aws-admin+newaccount@ses.com"
     name   = "ses-newaccount-dev"
     ou_id  = data.aws_organizations_organizational_unit.workload_dev.id
   }
   ```
4. Commit the change and open a Pull Request.
5. The `Terraform PR Checks` workflow will validate the change. Ensure no existing accounts are modified in the plan output.
6. Merge the PR. The `Terraform Apply` workflow will provision the account.
7. Upon completion, log into AWS Identity Center. The new account will be available, and the default permission sets (AdministratorAccess, ViewOnlyAccess) will be automatically pushed if they target the OU.

1. Record the account purpose, business owner, technical owner, environment, proposed OU, data classification, budget/cost center, target Regions, and required service quotas.
2. Obtain security approval for SCP baseline, log retention, KMS/Secrets ownership, exception process, break-glass role, and whether Macie applies. Obtain network approval for IPAM allocation, TGW route domain, DNS, endpoints, egress, and on-premises reachability.
3. Confirm the account name/email, GitHub OIDC repository/environment subject, least-privilege plan/apply/drift roles, and IAM Identity Center permission sets. Do not create IAM users or long-lived access keys.
4. Confirm no CIDR, ASN, DNS, Region, or account identifier is being inferred from the source placeholders.

## Controlled execution

1. Submit the Account Factory for Terraform request through the approved AFT root and approved pipeline; use the vending parameters reviewed in preflight.
2. Wait for the vending workflow, Control Tower baseline, SCP attachment, and account moves to reach their terminal success states. Do not start workload Terraform while any baseline is pending or failed.
3. Apply only the approved account customizations: organization logging/Config/GuardDuty/Security Hub delegation, account-level encryption and S3 public-access controls, IAM Identity Center assignments, and the scoped OIDC roles.
4. Add the account to the correct centralized observability/log/archive relationships. Grant no direct cross-environment state access.

## Acceptance evidence

- Account ID/name, OU placement, change record, and AFT/Control Tower execution identifiers.
- SCP and permission-boundary inventory; IAM Identity Center group/permission-set mapping; OIDC trust-policy subject and role-policy review.
- CloudTrail organization trail, Config recorder, GuardDuty, Security Hub, Inspector/Access Analyzer where applicable, central log delivery, KMS key ownership, and S3 Block Public Access evidence.
- A passing [`verify_security_read_only.sh`](../../tests/post_deploy/verify_security_read_only.sh) execution in the delegated Security/Audit account and a security-owner sign-off.
- No static AWS access key, Terraform backend credential, production secret, or customer data in the repository, state, or evidence bundle.

## Abort and rollback

If the baseline, OU, controls, logging, or OIDC boundary is incomplete, stop before deploying workloads. Remove unapproved role assignments and access grants, preserve CloudTrail/AFT evidence, and escalate through the change process. Account closure is a separately authorized, high-impact action; this runbook does not authorize it.
## Rollback
If the apply fails, do **not** run `terraform destroy`. Fix the Terraform error in a forward-fix PR. Deleting an `aws_organizations_account` removes it from the Org but does not close it (requires root email manual login).
