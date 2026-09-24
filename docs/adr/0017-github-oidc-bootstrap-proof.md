# ADR 0017: Bootstrap GitHub OIDC with a non-mutating proof boundary

**Status:** Superseded for sandbox OIDC ownership by ADR 0022
**Decision date:** 2026-09-20

## Context

The platform requires GitHub Actions to use short-lived AWS credentials rather
than stored keys. The existing source correctly provides reusable plan, apply,
and drift workflow contracts, but it intentionally contains no active AWS
identity, GitHub environment, or AWS OIDC provider. That means neither an AWS
trust policy nor the remote GitOps controls can be tested.

The first OIDC trust is a bootstrap problem: GitHub cannot assume a role until
an authorized human has created the IAM OIDC provider and role. Enabling a broad
administrator role merely to solve that bootstrap problem would violate the
least-privilege and no-implicit-apply boundaries.

GitHub's AWS OIDC integration supports IAM evaluation of the standard `aud`
and `sub` claims. AWS cannot use GitHub custom claims to bind a role trust
policy to a particular workflow filename.

## Decision

1. `hatan4ik/devops-aws-infra` is the selected initial GitOps control
   repository. It uses protected `main` and the `dev`, `staging`, `prod`, and
   `landing-zone` GitHub deployment environments. A future repository split
   requires its own ADR and migration record.
2. A short-lived IAM Identity Center session historically performed a one-time
   CloudFormation bootstrap. The retired template is preserved in Git history
   only; it is not a deployment path.
   [ADR 0022](0022-terraform-owned-sandbox-delivery-identity.md) now adopts
   the GitHub OIDC provider and roles into Terraform and retires that stack.
3. The only credentialed root workflow authorized before a root-specific policy
   and backend exist is
   [`oidc-sandbox-proof.yml`](../../.github/workflows/oidc-sandbox-proof.yml).
   It runs only by manual dispatch in the protected `dev` environment, exchanges
   a GitHub OIDC token for the permissionless role, and calls only
   `sts:GetCallerIdentity`.
4. Every IAM trust policy binds `token.actions.githubusercontent.com:aud` to
   `sts.amazonaws.com` and binds `sub` to the immutable repository subject plus
   an approved pull-request or deployment environment suffix. GitHub branch
   rules, CODEOWNERS, protected environments, and SHA-pinned actions enforce
   workflow provenance.
5. A Terraform plan, apply, or drift role gains AWS API permissions only in a
   later reviewed change that identifies the root, target account/Region,
   backend resources, exact permitted APIs, and rollback evidence. No role may
   receive `AdministratorAccess` as a bootstrap shortcut.
6. Control Tower launch, Account Factory, account vending, network, workload,
   and state migration remain out of scope for this bootstrap decision.

## Consequences

- The repository gains an end-to-end, auditable proof that GitHub can exchange
  an OIDC token without introducing static AWS credentials or an AWS mutation.
- The historical human action was explicit, narrow, and reproducible. Sandbox
  trust-anchor ownership now moves to Terraform under ADR 0022.
- IAM cannot distinguish an apply workflow from a drift workflow that uses the
  same protected environment subject. The roles remain separate and their
  privileges are independently reviewed; GitHub protection controls prevent
  unauthorized workflow changes.
- A single repository administrator cannot provide independent approval. Until
  independent reviewers are added, branch protection enforces pull requests and
  successful checks but cannot be represented as a four-eyes control.

## Alternatives rejected

1. **Store an IAM key in GitHub secrets.** Rejected because it creates a
   standing credential and violates ADR 0012.
2. **Grant an OIDC role `AdministratorAccess` to bootstrap delivery.** Rejected
   because its blast radius includes organization, IAM, and workload resources.
3. **Keep every root workflow credential-free forever.** Rejected because an
   isolated, permissionless proof is needed to validate the actual trust
   boundary before enabling Terraform delivery.
4. **Launch Control Tower in the same change.** Rejected because the required
   account quota, Log Archive/Audit accounts, and landing-zone inputs are
   unresolved and require a separate high-impact change record.
