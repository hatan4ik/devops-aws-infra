# Bootstrap AWS access

This runbook implements the access boundary in [ADR 0008](../adr/0008-security-and-state.md)
and [ADR 0012](../adr/0012-oidc-gated-terraform-delivery.md): humans use
short-lived IAM Identity Center sessions and CI uses environment-scoped GitHub
OIDC. Do not create, paste, commit, or configure long-lived IAM access keys for
this platform.

## Human access: IAM Identity Center

An AWS organization administrator must first enable IAM Identity Center,
create the least-privilege permission set for the approved bootstrap activity,
and assign the operator to the selected management or delegated account. Then
configure an SSO profile locally. The SSO start URL identifies the organization
but is not a credential; obtain it and the IAM Identity Center Region from the
organization administrator or the IAM Identity Center console. Do not copy a
profile, browser cache, or any values from `~/.aws/credentials` between people.

### First-time local configuration

```bash
aws configure sso --profile platform-bootstrap
aws sso login --profile platform-bootstrap
aws sts get-caller-identity --profile platform-bootstrap
```

Use the organization’s approved SSO start URL, SSO Region, account, role, and
default workload Region when prompted. Do not put a profile name in Terraform
source; an approved delivery environment supplies authentication at runtime.

During configuration, select only the account and permission set needed for
the activity. Use distinct local profiles for management, identity/security,
and sandbox/workload access; a profile name is a local convenience only, not
an authorization boundary. IAM Identity Center assignment, the selected
account, and the permission set remain the authorization boundary.

### Routine operator use

For each terminal session, select the local profile explicitly, authenticate,
and verify the account before an operational command:

```bash
export AWS_PROFILE=platform-bootstrap
aws sso login --profile "$AWS_PROFILE"
aws sts get-caller-identity --profile "$AWS_PROFILE"
aws configure list --profile "$AWS_PROFILE"
```

The final command must show `sso` as the source for both `access_key` and
`secret_key`. It will mask temporary values; do not paste its full output into
tickets, chat, logs, or source control. If the returned account or role is not
the approved target, stop. Never set `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, or `AWS_SESSION_TOKEN` to work around an SSO failure.

SSO sessions expire. When a command reports expired or unavailable SSO
credentials, rerun `aws sso login --profile "$AWS_PROFILE"`; do not create an
IAM access key. At the end of shared-device or incident work, sign out:

```bash
aws sso logout
unset AWS_PROFILE
```

### Operator preflight by account purpose

| Account purpose | Use it for | Do not use it for |
|---|---|---|
| Management | Organizations, Control Tower, billing/governance bootstrap | Routine workload changes |
| Identity/security delegated administration | IAM Identity Center, security-service delegation, approved identity changes | General application deployment |
| Sandbox/workload | Approved non-production plans and controlled workload changes | Organization-level governance actions |

Always run `aws sts get-caller-identity` immediately before a state migration,
Terraform plan, or apply. Record only the account ID, assumed-role name, and
timestamp as change evidence—never credential material.

## CI access: GitHub OIDC

Before enabling a credentialed plan/apply workflow, create an AWS IAM role in
the target account that trusts GitHub’s OIDC provider. Restrict the trust
policy to the exact GitHub repository, protected branch or environment, and
workflow conditions approved for that account. Grant only the actions required
for the specific root. Store no AWS access key in GitHub secrets.

Record the role ARN, target account, GitHub environment, required reviewers,
and plan/apply separation in the target repository’s protected-environment
configuration. The reusable workflow source is under
[`tooling/pipeline-templates`](../../tooling/pipeline-templates/);
it is not an enabled deployment path in this repository.

## Preflight

1. Confirm the caller identity and target account without printing credentials.
2. Confirm the intended root, Region, state backend, and approved input set.
3. Run a read-only plan from the authoritative backend and retain its review
   evidence before any apply.
4. Stop if identity, account, branch/environment protection, backend, or
   inputs differ from the approved change record.
