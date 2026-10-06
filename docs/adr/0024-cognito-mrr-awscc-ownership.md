# ADR 0024: Manage Cognito MRR with Terraform AWSCC resources

**Status:** Accepted — provider-backed replacement and CloudFormation retirement approved 2026-10-06.
**Decision date:** 2026-10-06

## Context

ADR 0011 correctly blocked imperative Cognito multi-Region replication (MRR)
side effects, and ADR 0020 temporarily selected CloudFormation because the
Terraform AWS provider did not expose the replica lifecycle. The maintained
HashiCorp AWS Cloud Control provider now exposes
`awscc_cognito_user_pool_replica` and
`awscc_cognito_user_pool_regional_configuration_attachment`. Together they
manage creation, secondary Region-local settings, and activation status as
Terraform resources without `local-exec`, console steps, or a nested
CloudFormation owner.

The AWS provider still cannot retrofit every primary-pool MRR prerequisite.
An eligible Essentials or Plus pool and matching regional replicas of one
symmetric multi-Region KMS key must exist before replica creation. Application
routing, token validation, regional SES/Lambda configuration, and Cognito's
secondary-write and TOTP limitations remain product and operational gates.

## Decision

Use `aws.modules.cognito//modules/multi-region-replication` with explicit
primary and `awscc.secondary` provider configurations. The module:

1. adopts an existing eligible primary user pool rather than pretending to
   retrofit unsupported key configuration;
2. validates that both KMS ARNs name regional replicas of the same `mrk-...`
   key in the expected account and Regions;
3. creates the one supported secondary replica and its Region-local
   configuration using provider-backed resources;
4. defaults the secondary to `INACTIVE`;
5. blocks activation until routing, authentication testing, token validation,
   write limitations, TOTP limitations, and an HTTPS failover runbook are all
   recorded as reviewed evidence; and
6. rejects activation when the primary requires software-token MFA, because
   the secondary does not support TOTP.

No active root may consume an unreleased branch. Publish a signed Cognito
module release, add a dedicated state boundary and least-privilege OIDC policy,
review the first plan, and create the secondary `INACTIVE`. Activation is a
separate approved change after a non-production authentication test. No
deployment is authorized by this ADR alone.

## Migration and ownership

- No active Cognito MRR CloudFormation stack was found in this repository's
  executable roots, so there is no CloudFormation resource to import or
  delete as part of this code uplift.
- If live discovery later finds an out-of-band replica or stack, stop. Record
  its identifiers and ownership, back up state, and approve an import/no-change
  migration before Terraform assumes ownership.
- The primary pool and MRR adoption may be separate states, but exactly one
  owner may manage each Cognito resource identity.
- The legacy `aws.modules.cloudformation` repository is not an approved MRR
  dependency. Archiving it is a separate repository-governance change after
  all consumers are proven absent.

## Consequences

- ADR 0011's provider-support condition is satisfied and ADR 0020's temporary
  CloudFormation ownership is superseded.
- MRR is now codeable, testable, importable, and drift-detectable through
  Terraform, but it is not deployed and does not make the platform
  production-ready.
- Provider aliases and prerequisite evidence are visible at the root call
  site, preventing an implicit wrong-Region deployment.
- Cognito remains primary/secondary for writes; application/data-plane
  active-active behavior is a different concern.
