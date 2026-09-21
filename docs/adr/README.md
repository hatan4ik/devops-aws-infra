# Architecture Decision Records

The active architecture record is the reviewed sequence below. ADR numbers are
unique within this list; a link in an implementation or runbook must resolve to
one of these files.

| ADR | Active decision |
|---|---|
| 0001 | [Control Tower and Account Factory for Terraform](0001-control-tower-account-vending.md) — superseded for account vending by ADR 0019 |
| 0002 | [Active-active regional availability and data](0002-regional-availability-and-data.md) |
| 0003 | [Segmented Transit Gateway, IPAM, and encryption](0003-segmented-tgw-ipam-and-encryption.md) |
| 0004 | [Static/dynamic ingress and conditional egress inspection](0004-edge-ingress-and-egress.md) |
| 0005 | [Dual Site-to-Site VPN with BGP](0005-hybrid-connectivity.md) |
| 0006 | [Cognito Essentials MRR and selective Verified Permissions](0006-identity-and-authorization.md) |
| 0007 | [ECS Fargate and DynamoDB global tables](0007-compute-and-data.md) |
| 0008 | [Security baseline and isolated Terraform state](0008-security-and-state.md) |
| 0009 | [Observability access and independent evidence retention](0009-observability-and-sre.md) |
| 0010 | [Repository and module topology](0010-repository-and-module-topology.md) |
| 0011 | [Cognito MRR provider boundary](0011-cognito-mrr-provider-boundary.md) — amended by ADR 0020 |
| 0012 | [OIDC-gated Terraform delivery](0012-oidc-gated-terraform-delivery.md) |
| 0013 | [Layered verification and no automatic fault injection](0013-layered-verification-no-automatic-fault-injection.md) |
| 0014 | [Canonical architecture and IaC boundary](0014-canonical-architecture-and-iac-boundary.md) |
| 0015 | [Adopt the legacy Terraform state bootstrap](0015-adopt-legacy-state-bootstrap.md) |
| 0016 | [Terraform state lock transition](0016-terraform-state-lock-transition.md) |
| 0017 | [GitHub OIDC bootstrap proof](0017-github-oidc-bootstrap-proof.md) |
| 0018 | [Sandbox network GitOps delivery](0018-sandbox-network-gitops-delivery.md) |
| 0019 | [Direct Organizations account vending; defer Control Tower and VPN](0019-direct-organizations-account-vending.md) |
| 0020 | [CloudFormation ownership for Cognito MRR lifecycle](0020-cognito-mrr-cloudformation-ownership.md) |
| 0021 | [Single-account sandbox platform core](0021-sandbox-platform-core-single-account.md) |
| 0022 | [Terraform-owned sandbox GitHub delivery identity](0022-terraform-owned-sandbox-delivery-identity.md) |

## Historical superseded records

The duplicate-number files ending in `account-structure`,
`multi-region-strategy`, `compute-platform`, `identity-provider`,
`egress-inspection`, `edge-ingress`, `fine-grained-auth`, `observability`, and
`repository-strategy` are retained for history only. They are superseded by
[ADR 0014](0014-canonical-architecture-and-iac-boundary.md) and must not be
used as implementation authority.
