# ADR 0011: Block Terraform deployment of Cognito MRR until it has a provider-backed resource

**Status:** Accepted — Phase 5 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

ADR 0002 selected Amazon Cognito multi-Region replication (MRR) for a primary/secondary identity directory. AWS exposes `CreateUserPoolReplica` and `UpdateUserPoolReplica`, and requires an MRR-capable user-pool tier plus `KeyConfiguration` with a multi-Region KMS key. The installed AWS provider schema exposes neither a replica/replication resource nor a Cognito user-pool KMS/issuer configuration field; its open MRR enhancement request is not an implementation contract. A Terraform plan that shells out to a CLI or expects a manually created replica cannot accurately manage, import, test, or destroy this critical identity state.

## Options considered

1. Invoke the AWS CLI/SDK through `local-exec` from Terraform to create, activate, and update a replica.
2. Create and operate the replica manually in the AWS console while Terraform manages only the primary user pool.
3. Use the provider-backed secure primary-pool module now, explicitly reject `replication.enabled = true`, and block MRR deployment until a maintained provider resource can manage the AWS APIs with import, plan, and test coverage.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** Identity failover is a system boundary and must not be represented by invisible imperative side effects. |
| Network Engineer | **Approve 3.** Regional routing cannot be declared ready when replica lifecycle and health-routing configuration are outside the plan. |
| Security Engineer | **Approve 3.** A local provisioner would create unreviewable credentials, audit, and rollback paths for a security-critical resource. |
| SRE | **Dissent: prefer 1.** A tightly controlled CLI wrapper could reach the AWS API sooner, but it cannot provide Terraform's full drift/import lifecycle and would require a separate operational control plane. |
| Platform/DevOps Lead | **Approve 3.** A hard plan-time guard is safer and reversible; a provider-backed resource can be adopted through a versioned migration when available. |

**Result:** 4–1 for option 3. The dissent is recorded; option 3 is the recommendation.

## Decision

Implement only the secure primary-pool contract in `terraform-aws-cognito-userpool`. It provides typed feature-plan, password, MFA, OAuth client, scope, and deletion-protection inputs. It rejects `replication.enabled = true` at plan time through an explicit precondition and marks MRR as `blocked-provider-support` in its output. It is not a deployable substitute for the required KMS-backed MRR identity directory.

Do not use `local-exec`, an untracked AWS CLI/SDK script, or console steps as a substitute. An amendment requires evidence that the selected provider exposes all required MRR operations, an import/migration plan for any existing replica, exact AWS IAM permissions, test coverage for create/activate/failover configuration, and stakeholder approval.

## Consequences

- Option 1 is rejected: it creates state outside Terraform, introduces secrets/credentials and failure recovery that are not part of the declarative plan, and makes drift detection unreliable.
- Option 2 is rejected: it makes a production availability control manual and unreviewable as code.
- Phase 5 cannot be called a deployable multi-Region identity implementation while this guard remains. The rest of the Terraform contract can be linted and unit-tested without claiming that MRR is deployed.
- This is a provider capability blocker, not authorization to change the selected identity architecture or create a self-managed identity system.
