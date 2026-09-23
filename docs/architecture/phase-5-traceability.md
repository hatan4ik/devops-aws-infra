# Phase 5 implementation traceability

**Status:** Historical Phase 5 design snapshot. For verified current AWS
delivery, read [Project status](../PROJECT-STATUS.md). The source mapped here
is candidate-only unless an ADR and root-specific GitHub workflow promote it.

| Brief requirement | Evidence | Status |
|---|---|---|
| Typed/described/validated module inputs; no module provider blocks; pinned requirements; stable `for_each`; outputs | [Module catalog](../MODULE-REPOSITORIES.md). | Versioned source is locally validated in each module repository; it is not evidence of a platform deployment. |
| VPC private subnets, IPAM allocation, endpoint contract, Flow Logs, KMS log encryption, VPC encryption control | [VPC module](https://github.com/hatan4ik/aws.modules.vpc/tree/v0.3.0). | Candidate source; CIDRs, endpoints, KMS key, retention, and a reviewed primary/secondary Region registry are unpopulated approved inputs. |
| TGW encryption, no default association/propagation/auto-accept, fixed route domains, RAM sharing | [TGW hub and routing modules](https://github.com/hatan4ik/aws.modules.tgw/tree/v0.2.0) and [attachment module](https://github.com/hatan4ik/aws.modules.tgw/tree/v0.2.0/modules/vpc-attachment). | Candidate source; peering, VPN/BGP, and cross-account acceptance await approved accounts/ASNs/CIDRs. |
| Secure Cognito authentication and MRR | [Cognito module](https://github.com/hatan4ik/aws.modules.cognito/tree/v0.1.1); [ADR 0011](../adr/0011-cognito-mrr-provider-boundary.md). | The active sandbox-platform contract exists; MRR remains blocked by provider lifecycle capability. |
| S3 state, SSE-KMS, versioning, Object Lock decision, DynamoDB locking, only CI/break-glass access | [State-backend module](https://github.com/hatan4ik/aws.modules.state/tree/v0.1.0); [foundation root](../../infra/candidates/roots/foundation/region-a/shared/); [bootstrap adoption root](../../infra/candidates/roots/foundation/region-a/bootstrap-state/); [ADR 0015](../adr/0015-adopt-legacy-state-bootstrap.md). | Future multi-tier design is candidate source; state-address migration and access-policy hardening remain gated. |
| Roots contain module calls only, one per account/Region/environment, with `providers.tf`, `backend.tf`, and environment tfvars | [Candidate root inventory](../../infra/candidates/roots/). | Candidate foundation, two regional network hubs, and a two-region dev/staging/prod workload skeleton; `region-a`/`region-b` are placeholders. |
| Identical dev/staging/prod structure; promotion changes inputs rather than code | [Dev roots](../../infra/candidates/roots/workload-dev/), [staging roots](../../infra/candidates/roots/workload-staging/), [prod roots](../../infra/candidates/roots/workload-prod/). | Candidate source; sizing and deployable inputs are intentionally unpopulated. |
| Examples/tests and terraform-docs README per reusable module | [Module test files](../../infra/); generated module READMEs. | Credential-free test evidence only; no test creates AWS resources. |

## Known implementation gates

1. Cognito MRR remains blocked by provider capability under ADR 0011. AWS API support alone is insufficient for a declarative Terraform lifecycle.
2. The observed bootstrap cannot be used as a general delivery backend until ADR 0015’s state-address migration is evidenced and its CI/break-glass roles, access policies, logging, retention, and recovery design are approved.
3. Account IDs, selected Regions, IPAM pools/CIDRs, TGW peer and VPN/BGP contracts, DNS zones/certificates, application image/runtime, data model, and compliance requirements remain external prerequisites. This code refuses to invent them.
4. Terraform 1.7+ is mandatory for no-credential mocked unit tests. The installed Terraform 1.7.5 validates the candidate modules and all ten foundation, network, dev, staging, and production-layout roots with `-backend=false`; it is not a claim that any AWS backend or resource has been accessed.
