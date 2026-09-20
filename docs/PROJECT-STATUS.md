# Project status and delivery authority

**Status as of 2026-09-20:** design and candidate Terraform source are under
version control; this repository is **not** proof of a deployed application
platform. The sandbox account contains the permissionless GitHub OIDC provider
and trust roles established by ADR 0017, plus the observed legacy state
bootstrap. ADR 0018 now supplies the approved isolated sandbox-network source,
dedicated state key configuration, and least-privilege policy bootstrap source;
its CloudFormation policy stack, GitHub role variables, and Terraform plan are
recorded. The first apply created a partial sandbox-network state and then
stopped on explicit least-privilege IAM denials; it is not a completed network
delivery until the corrective policy change is reviewed and Terraform
reconciles the same state.

## Start here

This document is the current operating status. Read it before a design chapter,
review snapshot, or Terraform directory.

| Question | Authoritative location |
|---|---|
| What is true now and what happens next? | This status document |
| Which architecture decision controls a change? | [ADR index](adr/README.md) |
| Which Terraform tree may become delivery source? | [`terraform/`](../terraform/README.md) only |
| What is the first bounded delivery slice? | [First delivery slice](delivery/first-delivery-slice.md) |
| What evidence is required before an AWS apply? | [External verification checklist](architecture/external-verification.md) |
| How is the selected legacy backend adopted safely? | [Adoption runbook](runbooks/adopt-legacy-state-backend.md) |
| What is the credential-free quality evidence? | [Terraform quality workflow](../.github/workflows/terraform-quality.yml) |

## Current delivery decision

**Selected milestone:** deliver the isolated sandbox-network root under
[ADR 0018](adr/0018-sandbox-network-gitops-delivery.md), while the broader
legacy state adoption in [ADR 0015](adr/0015-adopt-legacy-state-bootstrap.md)
remains independently gated. This scope is limited to sandbox account
`448871779014`, `us-east-2`, `10.64.0.0/16`, and a newly dedicated state key.

ADR 0018 authorizes only its versioned policy bootstrap and protected GitHub
workflow. It does **not** authorize a local Terraform apply, manual state
change, Control Tower launch, TGW/VPN/BGP, endpoint, workload, identity, data,
production, or multi-Region deployment. Do not claim the sandbox-network
delivery is complete until the reviewed GitHub plan and apply runs have
succeeded.

### Sandbox-network reconciliation record

The first GitHub apply created the private VPC, two private subnets, empty
route tables and associations, deny-all default security group, dedicated flow
log KMS key, encrypted CloudWatch Log Group, and flow-log IAM role. It then
stopped before VPC encryption control, KMS alias, flow-log role policy, and VPC
Flow Log because the apply role lacked three explicit actions. The remediation
must be a reviewed update to the versioned root-specific policy followed by a
GitHub re-apply; no console deletion or manual state edit is permitted.

## Delivery lanes

| Lane | Role | Do not treat it as |
|---|---|---|
| [`terraform/`](../terraform/README.md) | Candidate canonical Terraform delivery source; ADR 0018 is its one initialized-backend exception. | Proof that any AWS resource exists before the GitHub run evidence. |
| [`docs/`](README.md) | Current decisions, prerequisites, runbooks, and delivery contracts. | Evidence that AWS services are deployed. |
| [`automation/terraform-pipelines/`](../automation/terraform-pipelines/README.md) | Reviewed reusable workflow source for future roots. | The active ADR 0018 root-specific delivery workflows. |
| Root [`modules/`](../modules/README.md) and [`roots/`](../roots/README.md) | Disabled historical prototypes retained as forensic input. | A deployment path. |
| [`docs/book/`](book/README.md) | Explanatory design reference. | Status, approval, or implementation authority. |
| [`docs/reviews/archive/`](reviews/archive/README.md) | Historical point-in-time assessments. | A current backlog or current repository state. |

## Next milestone and stop conditions

1. Deploy the ADR 0018 policy stack using the documented sandbox SSO session
   and configure only its non-secret role-ARN GitHub variables.
2. Run and inspect the authoritative sandbox-network GitHub plan, then run the
   protected manual `dev` apply if it stays within the ADR 0018 resource list.
3. Preserve apply, CloudTrail, dedicated-state, and weekday-drift evidence.
4. Keep legacy state adoption, landing-zone launch, production networking,
   application, identity, and multi-Region work separately gated.

Stop immediately if the backend lock is active, a plan includes any resource
outside ADR 0018, the caller is not the sandbox account, a policy/bootstrap
value differs from source, or required run evidence is absent. Do not work
around an exception with manual state commands or console changes.

## Verified local evidence

The credential-free quality workflow is the repository's current automated
evidence for formatting, validation, mocked Terraform tests, policy scans, and
workflow checks. It validates source quality only; it does not authenticate to
AWS and cannot establish deployment equivalence or authorize an apply.

The [sandbox OIDC proof workflow](../.github/workflows/oidc-sandbox-proof.yml)
is separately verified remote evidence: it assumed the environment-scoped role
and called only `sts:GetCallerIdentity`. The role had no inline or attached
identity policies at proof time. ADR 0018 adds source for a later, separately
recorded root-specific policy bootstrap; do not conflate source with deployment
evidence.
