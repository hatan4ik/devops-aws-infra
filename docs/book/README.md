# AWS Platform Engineering Reference

**Edition:** 1.0 · **Status:** Design reference — pre-deployment
**Last reviewed:** 2026-09-18 · **Classification:** Internal Engineering

---

## About this documentation

This reference explains the design, architecture, and operational model for a
proposed AWS-native, multi-account, active-active multi-Region platform. It is
secondary explanatory material, not current deployment status, an approval
record, or implementation authority. Start with
[Project status](../PROJECT-STATUS.md) and the [ADR index](../adr/README.md).

No application, network, identity, or data-plane infrastructure, Terraform delivery state, or remote GitHub configuration has been created. ADR 0015 separately records an observed legacy state bootstrap and a still-gated canonical adoption path. Every document here otherwise describes design intent. The [external verification checklist](../architecture/external-verification.md) and [Phase 6–7 traceability](../architecture/phase-6-7-traceability.md) define what must be completed before any deployment begins.

---

## Document map

| Chapter | Document | Audience |
|---|---|---|
| 1 | [Platform Overview & ConOps](01-platform-overview.md) | All stakeholders |
| 2 | [Architecture Reference](02-architecture-reference.md) | Architects, engineers |
| 3 | [Network & Security Design](03-network-security.md) | Network, security engineers |
| 4 | [Identity, Compute & Data](04-identity-compute-data.md) | Application, identity engineers |
| 5 | [CI/CD Pipeline Design](05-cicd-pipeline.md) | DevOps, platform engineers |
| 6 | [Terraform Module Catalog](06-terraform-modules.md) | Infrastructure engineers |
| 7 | [SRE, Observability & Recovery](07-sre-observability.md) | SRE, operations |
| 8 | [Cost Model & FinOps](08-cost-model.md) | Finance, architects |
| 9 | [Architecture Decision Record Index](09-adr-index.md) | All engineers |
| 10 | [Operational Runbooks](10-runbooks.md) | Operations, SRE |
| 11 | [Verification & Testing Strategy](11-verification-testing.md) | QA, SRE, security |
| 12 | [Pre-Deployment Checklist](12-pre-deployment-checklist.md) | Platform leads, approvers |

---

> **Hard stop:** Do not add credentials, account IDs, CIDRs, or production values to any file in this repository.  
> See [Assumptions](../ASSUMPTIONS.md) for the full list of unresolved design inputs.
