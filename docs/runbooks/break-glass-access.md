# Runbook: break-glass access

## Trigger and scope

Use only for a severity-approved incident where normal IAM Identity Center, GitHub OIDC, and delegated administration cannot safely restore service. Break-glass is not an expedited deployment path, a workaround for failed review, or permission to bypass MFA, CloudTrail, SCPs, or state isolation.

## Preconditions

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
