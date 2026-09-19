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
configure an SSO profile locally:

```bash
aws configure sso --profile platform-bootstrap
aws sso login --profile platform-bootstrap
aws sts get-caller-identity --profile platform-bootstrap
```

Use the organization’s approved SSO start URL, SSO Region, account, role, and
default workload Region when prompted. Do not put a profile name in Terraform
source; an approved delivery environment supplies authentication at runtime.

## CI access: GitHub OIDC

Before enabling a credentialed plan/apply workflow, create an AWS IAM role in
the target account that trusts GitHub’s OIDC provider. Restrict the trust
policy to the exact GitHub repository, protected branch or environment, and
workflow conditions approved for that account. Grant only the actions required
for the specific root. Store no AWS access key in GitHub secrets.

Record the role ARN, target account, GitHub environment, required reviewers,
and plan/apply separation in the target repository’s protected-environment
configuration. The reusable workflow source is under
[`automation/terraform-pipelines`](../../automation/terraform-pipelines/);
it is not an enabled deployment path in this repository.

## Preflight

1. Confirm the caller identity and target account without printing credentials.
2. Confirm the intended root, Region, state backend, and approved input set.
3. Run a read-only plan from the authoritative backend and retain its review
   evidence before any apply.
4. Stop if identity, account, branch/environment protection, backend, or
   inputs differ from the approved change record.
