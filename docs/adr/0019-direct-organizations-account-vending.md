# ADR 0019: Use direct AWS Organizations account vending; defer Control Tower and VPN

**Status:** Accepted — stakeholder approval recorded 2026-09-21.
**Decision date:** 2026-09-21

## Context

The management account has AWS Organizations with all features enabled, three
existing accounts, and no Control Tower landing zone. The platform needs a
repeatable, reviewable account-vending path now. Control Tower's landing-zone
setup and Account Factory for Terraform are not prerequisites for secure direct
Organizations APIs, and using either would add a separate operational project
before the first network, security, and workload accounts can be created.

The approved initial Regions are `us-east-2` (primary), `us-west-2`
(secondary), and `us-east-1` for global-service control-plane dependencies.
The on-premises VPN/BGP inputs have not been supplied and are explicitly out
of this delivery slice.

## Decision

This ADR supersedes [ADR 0001](0001-control-tower-account-vending.md) only for
account vending. Use a direct, Terraform-managed AWS Organizations root and a
versioned CloudFormation bootstrap that creates its isolated state backend and
least-privilege GitHub OIDC role policies.

The root creates these top-level OUs: `Security`, `Platform`,
`Workloads-Production`, `Workloads-NonProduction`, `Sandbox`, and `Suspended`.
It creates and attaches a deny-organization-escape SCP and a three-Region SCP
to those OUs. It never attaches policy to the Organizations root, so the
management account remains outside the workload guardrails.

Account vending is map-driven. Every account entry must explicitly include its
unique email, human-readable name, parent OU, cost/owner tags, and the member
baseline change that will follow account creation. Empty account input is
valid and creates no account. Existing accounts are not moved or imported as a
side effect of this root.

GitHub Actions uses a pull-request plan role, an environment-bound
`landing-zone` apply role, and a non-remediating drift role. The apply workflow
checks out the default branch and requires the literal `apply` confirmation.
Human operators use IAM Identity Center only for the one-time CloudFormation
bootstrap and evidence inspection; no IAM user or long-lived key is introduced.

VPN/BGP, Customer Gateway creation, and TGW VPN attachments are deferred. They
remain governed by [ADR 0005](0005-hybrid-connectivity.md) and cannot be
implemented until the two on-premises public IPs, BGP ASN, approved prefixes,
route-domain matrix, and incident owner are committed as reviewed inputs.

## Consequences

- Control Tower and AFT are not created in this platform delivery; adopting
  either later needs a separate migration ADR and state/import plan.
- The management control plane has its own KMS-encrypted, versioned,
  Object-Lock-enabled S3 backend and DynamoDB lock table. It is not allowed to
  reuse sandbox state or credentials.
- The direct Organizations role necessarily uses AWS Organizations API actions
  with `Resource: "*"`, because AWS does not support resource-level scoping for
  the required create/list APIs. Its trust boundary, dedicated state prefix,
  explicit Terraform root, protected environment, and no-member-account policy
  limit the blast radius.
- OUs and SCPs can be applied once the GitHub environment protection is
  configured. Account creation stays blocked—not merely undocumented—until
  explicit emails and per-account input are added to reviewed tfvars.
- No VPN, BGP, on-premises route, or Customer Gateway resource is in scope for
  this milestone.
