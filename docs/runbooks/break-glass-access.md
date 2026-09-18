# Runbook: Break-Glass Access

## Purpose
Procedure to gain emergency access to an AWS account when CI/CD or standard IAM Identity Center (SSO) login is unavailable or broken.

## Prerequisites
- Physical MFA token for the Management Account Root user, locked in a secure physical location.
- Emergency Approval from the CISO or Platform Lead.

## Procedure
1. Retrieve the Root User credentials and physical MFA token from the vault.
2. Log into the AWS Management Console as the Root User for the Management Account.
3. If Identity Center is entirely down, navigate to AWS IAM in the specific workload account.
4. Create a temporary IAM User with `AdministratorAccess`.
5. Generate an Access Key and Secret Key.
6. Execute the required emergency Terraform fixes locally using `BypassSandbox: true` equivalent or direct CLI access.

## Post-Incident Cleanup (Mandatory)
1. Delete the temporary IAM User.
2. Rotate the Root User password.
3. Return the physical MFA token to the vault.
4. An incident report MUST be filed documenting why the break-glass procedure was invoked. CloudTrail logs will alert the Security Operations Center (SOC) immediately upon root login.
