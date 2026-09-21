# ADR 0020: Use CloudFormation for Cognito MRR lifecycle until Terraform has complete support

**Status:** Accepted — stakeholder approval recorded 2026-09-21.
**Decision date:** 2026-09-21

## Context

[ADR 0002](0002-regional-availability-and-data.md) requires an active-passive
Amazon Cognito user directory. The selected Terraform AWS provider still does
not manage the replica lifecycle, while AWS CloudFormation now exposes
`AWS::Cognito::UserPoolReplica`. Cognito MRR requires an eligible user pool,
a multi-Region customer-managed KMS key, replica activation, and separately
managed regional configuration.

The block in [ADR 0011](0011-cognito-mrr-provider-boundary.md) correctly
rejected `local-exec`, untracked CLI calls, and console-created replicas. It
does not need to block a versioned, declarative CloudFormation resource whose
stack lifecycle, parameters, outputs, and deployment identity are controlled
by GitOps.

## Decision

This ADR amends ADR 0011. Cognito MRR is owned entirely by a versioned
CloudFormation stack and its dedicated GitHub OIDC delivery policy until the
Terraform provider supports primary, replica, regional configuration,
activation, import, and drift management as one complete lifecycle.

Terraform must not manage a Cognito user pool that the MRR stack owns, and no
Terraform `local-exec`, custom provider, manual console action, or untracked
CLI call may bridge the two systems. A future Terraform migration requires an
approved import plan, a reviewed no-change plan, replica activation/failover
tests, and explicit removal of the CloudFormation owner.

The MRR stack will not be deployed until the following are versioned inputs:

- an approved public domain and Route 53 hosted-zone ownership;
- ACM certificates and health-check/failover routing decision;
- app-client callback/logout URLs and a workload artifact;
- approved email/SMS delivery configuration and user-notification owner;
- a multi-Region KMS key policy and the data/security owner; and
- a cost decision for the intended monthly active-user volume.

## Consequences

- The architecture still selects Cognito MRR; it is no longer described as an
  impossible provider blocker.
- A CloudFormation stack is a first-class, declarative infrastructure owner,
  not a one-off bootstrap script. It receives the same pull-request plan,
  protected apply, state/output, and drift evidence requirements as Terraform.
- A primary-only Terraform Cognito pool cannot be called a multi-Region
  identity deployment and is not eligible for production traffic.
