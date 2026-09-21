# GitHub OIDC bootstrap and activation

This historical runbook describes the former CloudFormation trust anchor. For
the sandbox, [ADR 0022](../adr/0022-terraform-owned-sandbox-delivery-identity.md)
adopts that provider and its roles into Terraform; use the
[sandbox delivery IAM adoption](sandbox-delivery-iam-adoption.md) runbook
instead. It does **not** launch Control Tower,
create accounts, alter Terraform state, or grant permission to modify AWS
resources.

## Security model

The historical CloudFormation stack created the GitHub OIDC provider and
separate plan, environment-apply, drift, and landing-zone roles. Those
resources now become Terraform-owned in the sandbox. Every role starts with
**no identity permissions**. A reviewed Terraform policy and state-backend
access are required before a
Terraform plan or apply can run.

AWS IAM can verify GitHub's `aud` and `sub` claims. It cannot enforce GitHub
custom claims such as a workflow filename. The controls are therefore split:

| Control | Enforced by |
|---|---|
| Immutable repository/environment subject and `sts.amazonaws.com` audience | AWS IAM role trust policy |
| Which workflow revision may run | Protected `main`, pull-request checks, CODEOWNERS, SHA-pinned actions |
| Who may authorize a deployment | GitHub deployment environment reviewers and branch restrictions |
| What AWS changes a role may make | Per-root least-privilege IAM policy and state-resource policy |

This repository uses GitHub's immutable OIDC subject format, as confirmed by
the repository OIDC settings on 2026-09-21. Its plan subject is
`repo:hatan4ik@12816536/devops-aws-infra@1375932356:pull_request`; environment
roles use the same immutable prefix plus `:environment:<name>`. Do not replace
the owner/repository IDs with the legacy slug-only subject.

The plan role also allows
`repo:hatan4ik@12816536/devops-aws-infra@1375932356:ref:refs/heads/main` so
the explicitly manual, read-only plan workflow can run from protected `main`.
No feature-branch ref is trusted.

## Preconditions

1. Run [`scripts/reconcile-github-controls.sh`](../../scripts/reconcile-github-controls.sh)
   with a GitHub principal that administers `hatan4ik/devops-aws-infra`.
2. Verify GitHub reports protected `main` and the `dev`, `staging`, `prod`, and
   `landing-zone` environments.
3. Log in through IAM Identity Center to the intended target account. Do not use
   the legacy IAM key profile.
4. Confirm the account and role with `aws sts get-caller-identity`.

## Historical one-time AWS bootstrap

Do not execute a CloudFormation bootstrap or reconciliation script for the
sandbox. The former templates and scripts are retained only as audit evidence
under [`archive/cloudformation-sandbox-bootstrap`](../../archive/cloudformation-sandbox-bootstrap/)
and intentionally exit without action. Follow
[sandbox delivery IAM adoption](sandbox-delivery-iam-adoption.md) instead.

## Promotion to Terraform delivery

For each canonical Terraform root, a separate reviewed pull request must:

1. define the exact resources and API actions for that root;
2. grant only those actions to that root's apply role, and read-only actions to
   plan/drift roles;
3. grant the minimum S3/KMS/DynamoDB state access to that role;
4. configure a protected environment variable with the target role ARN and an
   environment-scoped backend configuration secret;
5. run a non-mutating plan, retaining the CloudTrail, state-lock, policy-scan,
   and cost evidence; and
6. enable apply only after the plan and environment gate have been accepted.

Do not attach `AdministratorAccess`, reuse a role across accounts or
environments, or use GitHub repository secrets for AWS credentials.

The first approved exception is the isolated sandbox network in
[ADR 0018](../adr/0018-sandbox-network-gitops-delivery.md). Follow its
[delivery runbook](sandbox-network-delivery.md) exactly; it supplies the
root-specific policy, dedicated state key, and manual apply control. It does
not authorize any other root or the landing-zone control plane.

## Current limitations

Control Tower/Account Factory provisioning remains deliberately outside this
bootstrap until the organization account quota is approved and the Log Archive
and Audit accounts exist. The landing-zone role is created permissionless now
so its immutable trust subject can be reviewed before the later, high-impact
policy is granted.
