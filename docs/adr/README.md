# Architecture Decision Records

Read the [documentation sequence](../README.md) before using an ADR. ADR
numbers are unique, and this index owns their status. Only an **Accepted**
decision is authority, and only to the extent that a later ADR has not amended
or superseded it. **Proposed** means not approved; **Closed** and
**Superseded** are historical context.

| ADR | Status | Decision record |
|---|---|---|
| 0001 | Superseded by 0019 for account vending | [Control Tower and Account Factory for Terraform](0001-control-tower-account-vending.md) |
| 0002 | Accepted | [Active-active regional availability and data](0002-regional-availability-and-data.md) |
| 0003 | Accepted | [Segmented Transit Gateway, IPAM, and encryption](0003-segmented-tgw-ipam-and-encryption.md) |
| 0004 | Accepted | [Static/dynamic ingress and conditional egress inspection](0004-edge-ingress-and-egress.md) |
| 0005 | Accepted | [Dual Site-to-Site VPN with BGP](0005-hybrid-connectivity.md) |
| 0006 | Accepted | [Cognito Essentials MRR and selective Verified Permissions](0006-identity-and-authorization.md) |
| 0007 | Accepted | [ECS Fargate and DynamoDB global tables](0007-compute-and-data.md) |
| 0008 | Accepted | [Security baseline and isolated Terraform state](0008-security-and-state.md) |
| 0009 | Accepted | [Observability access and independent evidence retention](0009-observability-and-sre.md) |
| 0010 | Accepted | [Repository and module topology](0010-repository-and-module-topology.md) |
| 0011 | Superseded by 0024 after its provider condition was satisfied | [Cognito MRR provider boundary](0011-cognito-mrr-provider-boundary.md) |
| 0012 | Accepted | [OIDC-gated Terraform delivery](0012-oidc-gated-terraform-delivery.md) |
| 0013 | Accepted | [Layered verification and no automatic fault injection](0013-layered-verification-no-automatic-fault-injection.md) |
| 0014 | Accepted | [Canonical architecture and IaC boundary](0014-canonical-architecture-and-iac-boundary.md) |
| 0015 | Closed | [Adopt the legacy Terraform state bootstrap](0015-adopt-legacy-state-bootstrap.md) |
| 0016 | Proposed | [Terraform state lock transition](0016-terraform-state-lock-transition.md) |
| 0017 | Superseded by 0022 for Sandbox OIDC ownership | [GitHub OIDC bootstrap proof](0017-github-oidc-bootstrap-proof.md) |
| 0018 | Accepted; IAM ownership superseded by 0022 | [Sandbox network GitOps delivery](0018-sandbox-network-gitops-delivery.md) |
| 0019 | Accepted | [Direct Organizations account vending; defer Control Tower and VPN](0019-direct-organizations-account-vending.md) |
| 0020 | Superseded by 0024 | [CloudFormation ownership for Cognito MRR lifecycle](0020-cognito-mrr-cloudformation-ownership.md) |
| 0021 | Accepted; IAM ownership superseded by 0022 | [Single-account sandbox platform core](0021-sandbox-platform-core-single-account.md) |
| 0022 | Accepted | [Terraform-owned sandbox GitHub delivery identity](0022-terraform-owned-sandbox-delivery-identity.md) |
| 0023 | Accepted | [Protected sandbox application-plane teardown](0023-protected-sandbox-application-plane-teardown.md) |
| 0024 | Accepted | [Terraform AWSCC ownership for Cognito MRR](0024-cognito-mrr-awscc-ownership.md) |
