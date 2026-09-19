# Chapter 9 — Architecture Decision Record Index

**Status:** Active architecture record; ADRs 0001–0013 stakeholder-approved
2026-09-18, ADR 0014 accepted 2026-09-19, and ADR 0015 accepted for
source/migration planning 2026-09-19.
**Source:** [`docs/adr/`](../adr/)

Architecture Decision Records (ADRs) capture the context, options considered, quorum review, decision, and consequences for every significant design choice. They are the authoritative record of why the platform is designed the way it is.

---

## ADR summary table

| ADR | Title | Status | Key decision |
|---|---|---|---|
| [0001](../adr/0001-control-tower-account-vending.md) | Control Tower account vending | Accepted | AWS Control Tower + AFT for governed multi-account landing zone and account vending as code |
| [0002](../adr/0002-regional-availability-and-data.md) | Regional availability and data | Accepted | Active-active application/data plane; Cognito managed replication for primary/secondary identity |
| [0003](../adr/0003-segmented-tgw-ipam-and-encryption.md) | Segmented TGW, IPAM, and encryption | Accepted | Regional TGW hubs, IPAM, encryption controls, RAM sharing, explicit deny-by-default route segmentation |
| [0004](../adr/0004-edge-ingress-and-egress.md) | Edge ingress and egress | Accepted | CloudFront/WAF for static; Global Accelerator to regional ALBs for dynamic API; no Internet egress by default |
| [0005](../adr/0005-hybrid-connectivity.md) | Hybrid connectivity | Accepted | Dual Site-to-Site VPN/BGP per Region to TGW; Direct Connect only after costed demand case |
| [0006](../adr/0006-identity-and-authorization.md) | Identity and authorization | Accepted | Cognito Essentials + MRR; Verified Permissions only for selected fine-grained decisions |
| [0007](../adr/0007-compute-and-data.md) | Compute and data | Accepted | ECS Fargate baseline; DynamoDB global tables; Aurora Global and ElastiCache conditional |
| [0008](../adr/0008-security-and-state.md) | Security and state | Accepted | Org-wide preventive/detective controls, KMS/Secrets Manager, S3/DynamoDB state design |
| [0009](../adr/0009-observability-and-sre.md) | Observability and SRE | Accepted | Central observability/security accounts, CloudWatch/OAM/ADOT, SLOs, tested failover operations |
| [0010](../adr/0010-repository-and-module-topology.md) | Repository and module topology | Accepted | Hybrid live-root/module topology, three initial independently released modules, planned GitHub controls |
| [0011](../adr/0011-cognito-mrr-provider-boundary.md) | Cognito MRR provider boundary | Accepted | Block Cognito MRR pending Terraform provider support; no CLI/console substitution |
| [0012](../adr/0012-oidc-gated-terraform-delivery.md) | OIDC-gated Terraform delivery | Accepted | Separate OIDC plan/apply/drift roles, protected environments, SHA-pinned CI, no automatic remediation |
| [0013](../adr/0013-layered-verification-no-automatic-fault-injection.md) | Layered verification, no automatic fault injection | Accepted | Layered credential-safe verification; controlled game days rather than automatic disruptive tests |
| [0014](../adr/0014-canonical-architecture-and-iac-boundary.md) | Canonical architecture and IaC boundary | Accepted | One authoritative ADR sequence and `terraform/` as the only candidate delivery tree; root-level prototypes are disabled |
| [0015](../adr/0015-adopt-legacy-state-bootstrap.md) | Legacy state-bootstrap adoption | Accepted for source/migration planning | Transitional canonical root and an explicitly gated state-address migration; no live resource mutation |

The duplicate-number ADR files retained under `docs/adr/` are historical only
and are superseded by ADR 0014. Consult the [ADR index](../adr/README.md) for
the active record.

---

## Key rejected alternatives

| ADR | Rejected option | Reason |
|---|---|---|
| 0001 | Custom-only Terraform account vending | Recreates a landing-zone control plane without the supported governance baseline |
| 0001 | Console-only account vending | Not account vending as code; no repeatable, reviewable process |
| 0003 | Full-mesh VPC peering | Does not offer required scalable central segmentation |
| 0003 | One global shared VPC | Weakens account/workload isolation |
| 0007 | EKS as default compute | Adds Kubernetes control-plane/add-on/operations responsibilities without a supplied workload feature requiring them |
| 0012 | Static AWS credentials in GitHub secrets | Long-lived, hard to scope/audit; conflicts with credential boundary in ADR 0008 |
| 0012 | One broad OIDC admin role with automatic applies | Combines detection, authorization, and mutation; a faulty plan could alter network/identity/data controls without human review |

---

## ADR quorum model

Every ADR records a quorum review with the following roles:

| Role | Concern |
|---|---|
| Cloud Architect | Overall design integrity and cross-cutting trade-offs |
| Network Engineer | Connectivity, routing, BGP, DNS, and hybrid |
| Security Engineer | Controls, credentials, compliance, and blast radius |
| SRE | Operability, observability, failover, and runbook feasibility |
| Platform/DevOps Lead | CI/CD, module lifecycle, and GitHub delivery model |

A dissent is recorded with the dissenter's concern and the majority rationale. ADR 0001 is the only 4–1 decision (Security Engineer dissented on AFT's enlarged control plane; the concern is recorded as a consequence and constraint).

---

## How to write a new ADR

New ADRs are required for:
- Any change to a module's public interface (major version)
- Any new AWS service added to the platform baseline
- Any change to the CI/CD credential model or OIDC trust boundaries
- Any change to the account/OU structure
- Any relaxation of a security control

Template:

```markdown
# ADR NNNN: <Title>

**Status:** Proposed | Accepted | Superseded by NNNN
**Decision date:** YYYY-MM-DD

## Context
## Options considered
## Quorum review
## Decision
## Consequences
```
