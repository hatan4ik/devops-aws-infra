# ADR 0018: Deliver the isolated sandbox network through GitHub OIDC

**Status:** Accepted — IAM delivery-policy ownership superseded by ADR 0022
**Decision date:** 2026-09-20

## Context

The state backend, protected GitHub repository, environments, and permissionless
OIDC trust proof from ADR 0017 now exist. The user has explicitly approved the
first infrastructure scope: a new sandbox-network Terraform state object and
the `10.64.0.0/16` CIDR in AWS account `448871779014`, Region `us-east-2`.

The organization-wide IPAM, Transit Gateway, Control Tower, account-vending,
security account, and production landing zone remain unresolved. Requiring
those larger control-plane decisions would postpone the isolated, reversible
network slice unnecessarily. Conversely, using the historical state key,
long-lived credentials, a shared administrator role, or direct console/CLI VPC
creation would violate the delivery boundary.

## Decision

1. The canonical root is
   [`terraform/roots/sandbox-network/us-east-2/dev`](../../terraform/roots/sandbox-network/us-east-2/dev).
   Its immutable, dedicated S3 state key is
   `gitops/sandbox-network/us-east-2/dev/terraform.tfstate`.
2. The root is pinned to sandbox account `448871779014`, Region `us-east-2`,
   environment `dev`, and VPC CIDR `10.64.0.0/16`. Read-only preflight verified
   `us-east-2a` and `us-east-2b`; it allocates `10.64.0.0/20` and
   `10.64.16.0/20` respectively.
3. The first apply creates only a DNS-enabled private VPC, two private subnets,
   empty route tables, VPC encryption control, a deny-all default security
   group, a dedicated customer-managed KMS key, encrypted VPC Flow Logs, and
   the narrowly scoped log-delivery role. It creates no Internet Gateway, NAT,
   public subnet, endpoint, Transit Gateway attachment, VPN, workload, or
   identity/data-plane resource.
4. [ADR 0022](0022-terraform-owned-sandbox-delivery-identity.md) adopts the
   root-specific state, read, plan, drift, and apply policies into Terraform
   and retires the historical CloudFormation stack. Terraform owns the VPC and
   its delivery policy together after the controlled handoff.
5. GitHub Actions uses the immutable pull-request subject for plans and the
   protected `dev` environment subject for manual apply and scheduled drift.
   Role ARNs are non-secret GitHub variables configured only by the versioned
   setup script. No access key, secret key, profile, or backend credential is
   stored in source or GitHub.
6. A manual GitHub dispatch must type `apply`, re-plan protected `main`, and
   apply that exact binary plan. Drift runs on weekdays and fails when a change
   is found; it never remediates automatically.

## Consequences

- The state key is a separate blast-radius and recovery boundary; no historic
  state object is imported, moved, or edited.
- The VPC is deliberately isolated. A future TGW attachment, routes, VPN/BGP,
  inspection, or endpoint must be a separate reviewed Terraform change with an
  account/route-domain contract.
- The root uses direct CIDR assignment as the approved exception to the IPAM
  model. It must migrate only through a separately approved IPAM/state plan
  after the landing zone exists.
- The initial protected `dev` environment has no independent reviewer while
  this is a single-administrator repository. Manual dispatch and protected
  `main` provide traceability, but do not represent a four-eyes control.

## Alternatives rejected

1. **Create the VPC with ad hoc AWS CLI.** Rejected: it would leave no desired
   state, reviewed change, or reproducible destroy/update path.
2. **Reuse the legacy state key.** Rejected: it couples unrelated resources and
   weakens rollback and least-privilege policy scope.
3. **Wait for Control Tower/IPAM before any network.** Rejected for this
   sandbox-only, no-egress slice; the broader landing-zone decision remains
   explicitly required before shared/prod networking.
4. **Grant the existing OIDC role administrator access.** Rejected: the policy
   is root-specific and excludes Organizations, Control Tower, IAM Identity
   Center, TGW, public networking, and workloads.
