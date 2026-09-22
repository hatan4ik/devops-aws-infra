# Requirements traceability matrix

“Designed” and “gated” do not mean that AWS resources, a backend, or delivery
identity have been created. Evidence is deliberately separated from source: a
passing static test never becomes a claim that the corresponding service runs.

| Requirement | Design authority | Code / configuration | Automated verification | Required live evidence | Status |
|---|---|---|---|---|---|
| Reference inventory | [GitHub references](reference/github-repos.md), [local-project digest](reference/ses-projects-digest.md) | Review material only | Link validation in repository quality gate | Refreshed inventory date and repository owner confirmation | Partial — live inventory refresh is external. |
| Governed multi-account landing zone | [ADR 0001](adr/0001-control-tower-account-vending.md), [account-vending runbook](runbooks/account-vending.md) | No direct Organizations prototype | ADR boundary check | Control Tower/AFT account record and baseline-control evidence | Designed; approval-gated. |
| Two-Region availability and data | [ADR 0002](adr/0002-regional-availability-and-data.md), [assumptions A-01–A-07](ASSUMPTIONS.md) | [Regional candidate roots](../infra/candidates/roots/) | Terraform validation and module tests | Approved Regions, quotas, capacity/load and failover game-day evidence | Designed; prerequisites open. |
| Segmented networking and hybrid connectivity | [ADR 0003](adr/0003-segmented-tgw-ipam-and-encryption.md), [ADR 0005](adr/0005-hybrid-connectivity.md) | [TGW hub](https://github.com/hatan4ik/aws.modules.tgw/tree/v0.1.1), [network composition](../infra/candidates/modules/internal/network-regional/) | Module `terraform test` and read-only network verifier | CIDR/ASN approval, route-table, BGP tunnel and segmentation evidence | Designed; external inputs required. |
| Private ingress and conditional egress | [ADR 0004](adr/0004-edge-ingress-and-egress.md), [network security design](architecture/network-security.md) | Workload VPC and edge composition candidates | Terraform validation and security verifier | ALB/WAF/route configuration and approved egress exception evidence | Candidate implementation; no deployment. |
| Million-user authentication and authorization | [ADR 0006](adr/0006-identity-and-authorization.md), [ADR 0011](adr/0011-cognito-mrr-provider-boundary.md) | [Cognito module](https://github.com/hatan4ik/aws.modules.cognito/tree/v0.1.1) | Cognito module tests and AuthN/AuthZ synthetic contract | Quota approval, load test, provider-managed MRR lifecycle, and product auth results | Designed; MRR and capacity are blocked pending validation. |
| AWS-native compute and data plane | [ADR 0007](adr/0007-compute-and-data.md) | [Workload composition](../infra/candidates/modules/internal/workload-regional/) | Terraform validation and module tests | Application contract, capacity benchmark, data-model/restore evidence | Designed; not an AWS deployment. |
| Security and isolated state | [ADR 0008](adr/0008-security-and-state.md), [ADR 0015](adr/0015-adopt-legacy-state-bootstrap.md), [ADR 0016](adr/0016-terraform-state-lock-transition.md) | [State backend](https://github.com/hatan4ik/aws.modules.state/tree/v0.1.0), [adoption root](../infra/candidates/roots/foundation/region-a/bootstrap-state/) | Terraform tests; [ADR boundary check](../scripts/verify-adr-boundary.sh) | Specialist quorum, protected state backup, no-change plan/apply, refresh-only plan, restore drill, and cost baseline | Source ready for review; remote state remains gated. |
| Observability and SRE evidence | [ADR 0009](adr/0009-observability-and-sre.md), [operations design](architecture/operations.md) | Candidate observability contracts | Post-deploy read-only verifier contracts | Account destinations, SLO dashboards, alert routes, and game-day timeline | Designed; integration gated. |
| Repository topology and GitOps delivery | [ADR 0010](adr/0010-repository-and-module-topology.md), [ADR 0012](adr/0012-oidc-gated-terraform-delivery.md), [ADR 0014](adr/0014-canonical-architecture-and-iac-boundary.md) | [CI source](../.github/workflows/), [terraform-pipelines](https://github.com/hatan4ik/terraform-pipelines) | Terraform quality, actionlint, ShellCheck, pre-commit hooks | Branch rules, environments, OIDC roles, protected approvals, signed provenance | Active-root controls are delivered; candidate-root controls remain gated. |
| Verification and resilience | [ADR 0013](adr/0013-layered-verification-no-automatic-fault-injection.md), [runbooks](runbooks/README.md) | [Test contracts](../tests/) | Credential-free tests and read-only post-deploy scripts | Approved change record, synthetic results, VPN/BGP and failover game-day evidence | Contracted; live evidence pending deployment. |

## Architecture authority

Use [the ADR index](adr/README.md) and
[ADR 0014](adr/0014-canonical-architecture-and-iac-boundary.md) for the single
authoritative decision set. [`archive/prototypes/`](../archive/prototypes/) is
disabled historical material and is deliberately excluded from this matrix.
