# Phase 3: Target architecture summary

## Purpose and status

This is the reviewed target design for an AWS-native, multi-account,
two-Region platform. It is a design and candidate-source summary, not evidence
that an AWS organization, network, backend, workload, or identity service has
been provisioned.

## Authoritative decisions

- [ADR 0001](../adr/0001-control-tower-account-vending.md): Govern accounts
  with AWS Control Tower and Account Factory for Terraform.
- [ADR 0002](../adr/0002-regional-availability-and-data.md): Active-active
  application/data plane with defined identity failover semantics.
- [ADR 0003](../adr/0003-segmented-tgw-ipam-and-encryption.md): Regional TGW
  hubs, IPAM, route segmentation, and encryption controls.
- [ADR 0004](../adr/0004-edge-ingress-and-egress.md): CloudFront/WAF for
  static content; Global Accelerator and regional WAF-protected ALBs for
  dynamic APIs; no workload Internet route by default.
- [ADR 0005](../adr/0005-hybrid-connectivity.md): Dual IPsec/IKEv2 Site-to-Site
  VPN connections with eBGP per Region; Direct Connect is a measured upgrade.
- [ADR 0006](../adr/0006-identity-and-authorization.md) and
  [ADR 0011](../adr/0011-cognito-mrr-provider-boundary.md): Cognito and
  selective Verified Permissions, with MRR blocked until it has a managed
  Terraform lifecycle.
- [ADR 0007](../adr/0007-compute-and-data.md): ECS Fargate, Lambda for
  asynchronous/spiky work, and DynamoDB global tables where appropriate.
- [ADR 0008](../adr/0008-security-and-state.md) and
  [ADR 0009](../adr/0009-observability-and-sre.md): layered AWS-native
  security, isolated state, and centralized observability with independent log
  retention.

The complete active record is in the [ADR index](../adr/README.md). Duplicate
historical ADRs and the matching root-level prototype code are explicitly
superseded by [ADR 0014](../adr/0014-canonical-architecture-and-iac-boundary.md).

## Pre-deployment decision inputs

Before implementation, obtain the values and approvals in the
[external verification checklist](external-verification.md): target Regions,
data residency/RTO/RPO, CIDR and ASN allocations, customer-gateway endpoints,
identity traffic and quota headroom, DNS/certificates, KMS ownership, egress
need, state retention, and cost approval. The current cost model is a planning
artifact; it must be recalculated from these approved workload inputs before a
deployment decision.
