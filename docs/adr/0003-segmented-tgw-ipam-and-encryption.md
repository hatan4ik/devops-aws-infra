# ADR 0003: Use regional segmented Transit Gateway hubs, IPAM, and encryption controls

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

Multiple accounts, workload VPCs, Regions, and on-premises networks need controlled connectivity without overlapping address space or transitive access. The local OVP module is useful evidence of TGW/RAM primitives but defaults automatic attachment acceptance and has no required route-table segmentation.

## Options considered

1. Full-mesh VPC peering and per-VPC VPNs.
2. One global shared VPC with shared subnets and a centralized VPN gateway.
3. One TGW in each Region, AWS RAM sharing, TGW inter-Region peering, VPC IPAM allocation, encryption controls, and explicit segmented route tables.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** It scales account/VPC growth while preserving workload-account ownership. |
| Network Engineer | **Approve 3.** Explicit associations/propagations, BGP prefix control, and peering routes create auditable routing. |
| Security Engineer | **Approve 3.** Default route-table association and propagation must be disabled; routes alone do not grant access. |
| SRE | **Approve 3.** Regional fault domains and flow logs make failure isolation/testability practical. |
| Platform/DevOps Lead | **Approve 3.** Stable-key Terraform modules can separate TGW ownership, RAM sharing, attachment acceptance, and route programming. |

**Result:** 5–0 for option 3; no dissent.

## Decision

The Network account owns a TGW per Region, RAM shares, route tables, and peering attachments. Workloads own VPC attachments/route entries through narrowly scoped roles. IPAM assigns non-overlapping CIDRs from an enterprise-approved pool. TGWs disable default association, default propagation, and auto-accept shared attachments; attachments associate with exactly one of `prod`, `non-prod`, `shared`, `inspection`, or `on-prem` route tables.

Enable TGW encryption support and VPC Encryption Controls enforce mode where supported. Use TLS 1.2+ between services regardless of network encryption. Create explicit static routes for TGW peering; use BGP propagation only in the permitted on-prem/VPN tables.

## Consequences

- Each attachment costs money and must be named/tagged/justified; TGW data processing is usage-based.
- DNS requires regional Route 53 Resolver design because TGW peering does not make private DNS resolution a global default.
- Options 1 and 2 are rejected: mesh peering does not offer the required scalable central segmentation, and a shared VPC weakens account/workload isolation.
