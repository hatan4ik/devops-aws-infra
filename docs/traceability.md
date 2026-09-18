# Requirements Traceability Matrix

## Delivery Checklist mapping

| Requirement | Description | Evidence / Location | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1** | GitHub Reference Inventory | `docs/reference/github-repos.md` (Blocked by gh TLS, but gitOps initialized) | ⚠️ Partial |
| **Phase 2** | Local SES Projects Digest | `docs/reference/ses-projects-digest.md` | ✅ Complete |
| **Phase 3.1** | Requirements / Assumptions | `docs/ASSUMPTIONS.md` | ✅ Complete |
| **Phase 3.2** | Account Structure ADR | `docs/adr/0001-account-structure.md` | ✅ Complete |
| **Phase 3.3** | Network ADR (Inspection) | `docs/adr/0005-egress-inspection.md` | ✅ Complete |
| **Phase 3.4** | Identity & Application ADRs | `docs/adr/0004-identity-provider.md`, `docs/adr/0003-compute-platform.md` | ✅ Complete |
| **Phase 3.6** | Observability ADR | `docs/adr/0008-observability.md` | ✅ Complete |
| **Phase 3 (Out)**| Architecture Diagrams & Cost | `docs/architecture/diagrams.md`, `phase-3-summary.md` | ✅ Complete |
| **Phase 4** | Repo Strategy & Naming ADR | `docs/adr/0009-repository-strategy.md`, `phase-4-repositories.md` | ✅ Complete |
| **Phase 5** | Terraform Standards | `modules/aws-tf-state-backend/`, `modules/aws-vpc-workload/` | ✅ Complete |
| **Phase 5** | Roots Structure (Dev/Stg/Prd) | `roots/workload-app/us-east-1/{dev,staging,prod}/` | ✅ Complete |
| **Phase 6** | CI/CD Pipelines (GitOps) | `.github/workflows/*.yml` | ✅ Complete |
| **Phase 7** | Tests | `modules/*/tests/main.tftest.hcl` (tests pass) | ✅ Complete |
| **Deliverable 6**| Runbooks | `docs/runbooks/*.md` | ✅ Complete |

## Key Decisions
* **Organizations:** Custom Terraform organizations structure over Control Tower (GitOps purity).
* **Multi-Region:** Active-Active via Route 53 and DynamoDB Global Tables.
* **Compute:** ECS Fargate over EKS.
* **Identity:** Amazon Cognito.
* **Network Egress:** Decentralized NATs and VPC Endpoints, rejecting Network Firewall for cost savings.

## Open Questions & Blockers
1. **GitHub Auth**: TLS verification error on `api.github.com` prevents running `gh repo list`.
2. **Cognito Quota**: Need AWS Support confirmation that Cognito can be scaled to 5,000 RPS.
3. **On-Premise IPAM**: Need the assigned CIDR blocks from the networking team to inject into the `ipam-pool-xxxxxxxx` placeholders in `terraform.tfvars`.

## State of the Repository
* `modules/`: Contains strictly-typed, tested, and documented foundational modules (SOLID).
* `roots/`: Contains the environment deployments passing variables cleanly without bare resources.
* `.github/`: Contains full branch protection definitions (`CODEOWNERS`) and CI/CD pipelines.
