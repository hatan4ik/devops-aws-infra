# GitHub OIDC bootstrap and activation

This runbook establishes the one-time trust anchor that lets GitHub Actions
obtain short-lived AWS credentials. It does **not** launch Control Tower,
create accounts, alter Terraform state, or grant permission to modify AWS
resources.

## Security model

The initial CloudFormation stack creates the GitHub OIDC provider and separate
plan, environment-apply, drift, and landing-zone roles. Every role starts with
**no identity permissions**. It proves authentication only; a future change
must attach a reviewed, root-specific policy and state-backend access before a
Terraform plan or apply can run.

AWS IAM can verify GitHub's `aud` and `sub` claims. It cannot enforce GitHub
custom claims such as a workflow filename. The controls are therefore split:

| Control | Enforced by |
|---|---|
| Immutable repository/environment subject and `sts.amazonaws.com` audience | AWS IAM role trust policy |
| Which workflow revision may run | Protected `main`, pull-request checks, CODEOWNERS, SHA-pinned actions |
| Who may authorize a deployment | GitHub deployment environment reviewers and branch restrictions |
| What AWS changes a role may make | Per-root least-privilege IAM policy and state-resource policy |

## Preconditions

1. Run [`scripts/reconcile-github-controls.sh`](../../scripts/reconcile-github-controls.sh)
   with a GitHub principal that administers `hatan4ik/devops-aws-infra`.
2. Verify GitHub reports protected `main` and the `dev`, `staging`, `prod`, and
   `landing-zone` environments.
3. Log in through IAM Identity Center to the intended target account. Do not use
   the legacy IAM key profile.
4. Confirm the account and role with `aws sts get-caller-identity`.

## One-time AWS bootstrap

The repository already uses immutable OIDC subjects. Bootstrap the sandbox
first; this creates no resource permissions:

```bash
scripts/bootstrap-github-oidc.sh \
  --profile AWS-hatan4ik-sandbox \
  --region us-east-2 \
  --role-prefix devops-aws-infra-sandbox
```

Record the `DevApplyRoleArn` output as the `AWS_OIDC_PROOF_ROLE_ARN` **dev
environment variable** in GitHub. It is an ARN, not a secret. Do not store it
as an AWS access key or create a repository-level credential secret.

Then run **Verify sandbox OIDC** from `main`. A successful run proves GitHub
can assume the environment-scoped role but cannot alter AWS because the role
has no attached permissions.

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

## Current limitations

Control Tower/Account Factory provisioning remains deliberately outside this
bootstrap until the organization account quota is approved and the Log Archive
and Audit accounts exist. The landing-zone role is created permissionless now
so its immutable trust subject can be reviewed before the later, high-impact
policy is granted.
