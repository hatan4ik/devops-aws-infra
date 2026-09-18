# Runbook: break-glass access
# Runbook: Break-Glass Access

## Trigger and scope
## Purpose
Procedure to gain emergency access to an AWS account when CI/CD or standard IAM Identity Center (SSO) login is unavailable or broken.

Use only for a severity-approved incident where normal IAM Identity Center, GitHub OIDC, and delegated administration cannot safely restore service. Break-glass is not an expedited deployment path, a workaround for failed review, or permission to bypass MFA, CloudTrail, SCPs, or state isolation.
## Prerequisites
- Physical MFA token for the Management Account Root user, locked in a secure physical location.
- Emergency Approval from the CISO or Platform Lead.

## Preconditions
## Procedure
1. Retrieve the Root User credentials and physical MFA token from the vault.
2. Log into the AWS Management Console as the Root User for the Management Account.
3. If Identity Center is entirely down, navigate to AWS IAM in the specific workload account.
4. Create a temporary IAM User with `AdministratorAccess`.
5. Generate an Access Key and Secret Key.
6. Execute the required emergency Terraform fixes locally using `BypassSandbox: true` equivalent or direct CLI access.

1. Open an incident record with severity, affected account/Region, reason normal access is insufficient, requested scope, named operator, approver, and maximum session duration.
2. Obtain Security and incident-commander approval. If either role is unavailable, use the pre-approved emergency escalation roster and record the reason.
3. Require phishing-resistant MFA and the dedicated, monitored break-glass identity/role. Never use root credentials, shared passwords, static keys, or a personal access key. Root use requires its own emergency procedure and executive/security approval.
4. Define the smallest target resource/action set and a rollback/expiry time before elevation. The operator must not change unrelated network routes, SCPs, KMS policies, identity configuration, or Terraform state.

## Controlled execution

1. Grant/assume the time-bound break-glass role through the approved emergency access path. Record the resulting session identity and CloudTrail correlation, not credentials.
2. Perform only the documented recovery action. Prefer read-only diagnosis and reversible, scoped changes. A Terraform apply still needs its normal environment/change gate unless the incident commander and Security explicitly authorize the exception.
3. Maintain live incident notes of commands/actions, affected resources, expected result, actual result, and decision owner. Preserve CloudTrail, Config, application/ALB/WAF, TGW/VPN, and identity evidence.

## Exit and review

1. Remove the role assignment/session permission immediately after recovery or at its expiry. Verify with IAM Identity Center/IAM and CloudTrail that no standing privilege, access key, token, or policy attachment remains.
2. Run applicable read-only security/network/public checks, reconcile Terraform drift through a normal reviewed change, and ensure no secret appeared in evidence.
3. Conduct a post-incident review with Security, SRE, and platform owners: timeline, access scope/duration, justification, changes, customer effect, evidence, follow-up actions, and whether the standard access/runbook must improve.

Any inability to verify privilege removal or evidence preservation is a continuing security incident, not a completed break-glass event.
## Post-Incident Cleanup (Mandatory)
1. Delete the temporary IAM User.
2. Rotate the Root User password.
3. Return the physical MFA token to the vault.
4. An incident report MUST be filed documenting why the break-glass procedure was invoked. CloudTrail logs will alert the Security Operations Center (SOC) immediately upon root login.
