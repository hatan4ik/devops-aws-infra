# ADR 0022: Terraform owns sandbox GitHub delivery identity

**Status:** Accepted
**Decision date:** 2026-09-22

## Context

The sandbox GitHub OIDC provider, six roles, four root-specific delivery
policies, and their attachments were created by three CloudFormation stacks.
That split IAM ownership from the Terraform roots that depend on it. A policy
repair therefore required an IAM Identity Center operator to update
CloudFormation before the protected GitHub Terraform workflow could reconcile
the application root.

The selected sandbox state bucket already applies its customer-managed KMS key
as default S3 encryption. Terraform's S3 backend cannot interpolate Terraform
variables, so embedding an account-qualified KMS ARN in each backend file is
unnecessary and harms repeatability.

## Decision

1. [`terraform/roots/sandbox-delivery/us-east-2/global`](../../terraform/roots/sandbox-delivery/us-east-2/global)
   is the sole sandbox owner of the GitHub OIDC provider, six GitHub roles,
   four existing sandbox network/platform delivery policies, and all their
   role attachments.
2. The root uses declarative Terraform import blocks to adopt the existing
   resources without replacement or detachment. Its first, explicitly
   confirmed apply uses a short-lived IAM Identity Center session only because
   no OIDC role can manage itself before it exists in Terraform state.
3. After adoption, two Terraform-created policies give the existing plan,
   drift, and protected `dev` apply roles the narrow state and IAM APIs needed
   to plan, detect drift, and publish revisions of only the tracked sandbox
   delivery policies. No role receives `AdministratorAccess`.
4. Policy and resource ARNs are composed from `aws_account_id`, `aws_region`,
   AWS partition, names, and a KMS key UUID. Each root supplies its account ID
   once. The backend relies on the verified S3 bucket default KMS encryption
   rather than an account-qualified `kms_key_id` literal.
5. The three retired CloudFormation templates and their bootstrap scripts live
   only under [`archive/cloudformation-sandbox-bootstrap`](../../archive/cloudformation-sandbox-bootstrap/).
   The controlled handoff sets `Retain` metadata, deletes the stacks, and
   verifies Terraform ownership before the archive is left as evidence.
6. The management-account Organization bootstrap and the future Cognito MRR
   boundary are not changed by this sandbox migration. They require separate,
   account-specific Terraform adoption records; they are not justification for
   retaining sandbox CloudFormation ownership.

## Consequences

- Sandbox IAM policy changes follow the same reviewed plan, protected apply,
  drift detection, state isolation, and GitHub OIDC controls as the platform.
- A protected `dev` deployment can update only the defined sandbox delivery
  policies, their attachments, the approved OIDC roles, and the one GitHub
  OIDC provider. It cannot create users, access keys, accounts, VPCs, or a
  broad administrator policy.
- The root is reusable for a later account by supplying a different account
  contract and backend, but this root remains pinned to the approved sandbox
  account to prevent accidental cross-account delivery.
- The archived templates must never be used to create a new stack. They exist
  only for auditable retirement of the currently live stacks.
