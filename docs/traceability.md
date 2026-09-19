# Requirements Traceability Matrix

This matrix tracks the candidate source in this repository. “Designed” and
“gated” do not mean that AWS resources, a backend, or a delivery identity have
been created.

| Requirement | Authoritative evidence | Source boundary | Status |
|---|---|---|---|
| Reference inventory | [GitHub references](reference/github-repos.md) and [local-project digest](reference/platform-projects-digest.md) | Review material only; no reference clone is a dependency. | Partial — live inventory refresh is external. |
| Governed multi-account landing zone | [ADR 0001](adr/0001-control-tower-account-vending.md), [account-vending runbook](runbooks/account-vending.md) | Account vending is Control Tower/AFT work, not a direct Terraform Organizations prototype. | Designed; approval-gated. |
| Two-Region availability and data | [ADR 0002](adr/0002-regional-availability-and-data.md), [regional roots](../terraform/roots/) | Candidate roots are backend-disabled. | Designed; Regions, quotas, and data requirements remain prerequisites. |
| Segmented networking and hybrid connectivity | [ADR 0003](adr/0003-segmented-tgw-ipam-and-encryption.md), [ADR 0005](adr/0005-hybrid-connectivity.md), [network module](../terraform/modules/terraform-aws-tgw-hub/) | No CIDR, ASN, customer-gateway, or VPN secret values are committed. | Designed; external network inputs required. |
| Private ingress and conditional egress | [ADR 0004](adr/0004-edge-ingress-and-egress.md), [network security design](architecture/network-security.md) | Workload VPC candidate module has no public subnet or default Internet route. | Candidate implementation covered by credential-free checks. |
| Million-user authentication and authorization | [ADR 0006](adr/0006-identity-and-authorization.md), [ADR 0011](adr/0011-cognito-mrr-provider-boundary.md), [Cognito module](../terraform/modules/terraform-aws-cognito-userpool/) | Cognito MRR is explicitly blocked until provider-managed lifecycle support exists. | Designed; capacity, MRR, and authorization scope require external validation. |
| AWS-native compute and data plane | [ADR 0007](adr/0007-compute-and-data.md), [workload composition](../terraform/modules/internal/workload-regional/) | ECS/DynamoDB workload specifics await application contracts. | Designed; not an AWS deployment. |
| Security and isolated state | [ADR 0008](adr/0008-security-and-state.md), [ADR 0015](adr/0015-adopt-legacy-state-bootstrap.md), [state backend module](../terraform/modules/internal/state-backend/), [legacy bootstrap inventory](architecture/legacy-state-bootstrap.md) | No committed backend configuration, static key, or state. A separate bootstrap is represented by a transitional canonical root. | Adoption is approved for source/migration planning; remote state re-addressing and hardening remain gated. |
| Observability and SRE evidence | [ADR 0009](adr/0009-observability-and-sre.md), [operations design](architecture/operations.md) | Account IDs, destinations, and retention settings are external inputs. | Designed; integration remains gated. |
| Repository topology and GitOps delivery | [ADR 0010](adr/0010-repository-and-module-topology.md), [ADR 0012](adr/0012-oidc-gated-terraform-delivery.md), [pipeline source](../automation/terraform-pipelines/) | Quality is credential-free; plan/apply/drift workflow templates are not active AWS delivery paths here. | Source complete; remote controls and OIDC roles are uncreated. |
| Verification and resilience | [ADR 0013](adr/0013-layered-verification-no-automatic-fault-injection.md), [test contracts](../tests/) | No automatic remediation or fault injection. | Contracted; live evidence requires a deployed, approved environment. |

## Architecture authority

Use [the ADR index](adr/README.md) and [ADR 0014](adr/0014-canonical-architecture-and-iac-boundary.md) for the single authoritative decision set. The root-level `modules/` and `roots/` directories are disabled historical prototypes and are deliberately excluded from this matrix.
