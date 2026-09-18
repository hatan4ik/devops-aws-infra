# Runbook: Account Vending

## Purpose
Automated procedure for provisioning a new AWS account under the target Organizational Unit (OU).

## Prerequisites
- Identity Center (SSO) permissions for the root Management Account.
- Access to the `ses-aws-platform-roots/org` repository.

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

## Rollback
If the apply fails, do **not** run `terraform destroy`. Fix the Terraform error in a forward-fix PR. Deleting an `aws_organizations_account` removes it from the Org but does not close it (requires root email manual login).
