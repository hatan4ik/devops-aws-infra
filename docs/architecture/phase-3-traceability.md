# Phase 3 requirement traceability

| Brief requirement | Evidence | Status |
|---|---|---|
| 3.1: state users, concurrency, auth RPS, latency, availability, RTO/RPO, residency assumptions | [Assumptions A-01 through A-07](../ASSUMPTIONS.md); [ADR 0002](../adr/0002-regional-availability-and-data.md); [SLOs](operations.md). | Designed; values require external validation. |
| 3.2: Organizations accounts, OUs, Control Tower/custom decision, SCPs, vending | [Account/OU diagram](README.md); [ADR 0001](../adr/0001-control-tower-account-vending.md); [security controls](network-security.md). | Designed; Control Tower/AFT bootstrap is approval-gated. |
| 3.3: TGW hubs/peering, route segmentation, IPAM, private workload VPCs, ingress, VPN/BGP, TLS, endpoints, egress decision, DNS | [Network design](network-security.md); [ADR 0003](../adr/0003-segmented-tgw-ipam-and-encryption.md); [ADR 0004](../adr/0004-edge-ingress-and-egress.md); [ADR 0005](../adr/0005-hybrid-connectivity.md). | Designed; CIDR/ASN, endpoint list, and target Regions are external blockers. |
| 3.4: Cognito evaluation/ceiling, authorization, compute, data, edge, keys/secrets | [Platform design](platform.md); [ADR 0006](../adr/0006-identity-and-authorization.md); [ADR 0007](../adr/0007-compute-and-data.md); [cost model](cost-estimate.md). | Designed; Cognito MRR limits and cost require business approval. |
| 3.5: organization security baseline | [Security controls](network-security.md); [ADR 0008](../adr/0008-security-and-state.md). | Designed; each SCP/control needs staged implementation and test. |
| 3.6: CloudWatch/ADOT, SLOs, Security/SRE alerts, failover runbooks, game day, centralized observability | [Operations](operations.md); [ADR 0009](../adr/0009-observability-and-sre.md). | Designed; on-call destinations and retention are external prerequisites. |
| Phase 3: architecture diagrams, ADRs, cost per environment, external-verification list | [Architecture index](README.md), [nine ADRs](../adr/), [cost estimate](cost-estimate.md), [verification checklist](external-verification.md). | Complete and stakeholder-approved on 2026-09-18. |

Phase 4–7 local source and traceability now exist in their dedicated matrices. Remote GitHub changes, account vending, AWS roles/backends, Terraform plans/applies, and live verification remain separately approval-gated.
