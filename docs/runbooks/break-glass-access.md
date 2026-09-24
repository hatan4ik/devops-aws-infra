# Runbook: break-glass access

## Purpose

Use only for a severity-approved incident when IAM Identity Center, GitHub
OIDC, and delegated administration cannot safely restore service. Break-glass
is not an expedited deployment path and never permits root-console use, shared
passwords, static access keys, personal IAM users, or unreviewed Terraform
state changes.

## Preconditions

1. Open an incident record with the affected account/Region, requested action,
   named operator, incident commander, Security approver, and maximum session
   duration.
2. Define the smallest recovery scope and rollback/expiry before elevation.
3. Require phishing-resistant MFA and the dedicated monitored break-glass role.
   If that role is unavailable, escalate through the pre-approved emergency
   roster; do not create an IAM user or access key.

## Controlled execution

1. Assume the time-bound break-glass role through the approved emergency path.
   Record the resulting session identity and CloudTrail correlation, never a
   credential.
2. Perform only the documented, reversible recovery action. Prefer read-only
   diagnosis. An infrastructure apply still needs the normal environment and
   change gate unless the incident commander and Security explicitly authorize
   the exception.
3. Maintain incident notes of actions, affected resources, expected result,
   actual result, and decision owner.

## Exit criteria

1. Remove elevated access immediately after recovery or at expiry.
2. Verify privilege removal with IAM Identity Center/IAM and CloudTrail.
3. Reconcile any Terraform drift through a normal reviewed change.
4. Hold a Security/SRE/platform review and preserve the incident evidence.

Failure to verify privilege removal or preserve evidence is an ongoing security
incident, not a completed recovery.
