# Project status and delivery authority

**Status as of 2026-09-21:** the isolated ADR 0018 sandbox network has been
delivered through the protected GitHub OIDC workflow and verified read-only in
AWS. The management account now also has the ADR 0019 permissionless GitHub
OIDC provider and environment-scoped trust roles. A 2026-09-21 verification
found legacy OIDC trust subjects encoded with GitHub numeric IDs; they must be
updated to GitHub's standard `repo:OWNER/REPO` subject before another plan or
apply uses those roles. This repository is still
**not** proof of a deployed application platform: direct Organizations state
bootstrap, OU/SCP apply, account vending, TGW, workloads, identity, data,
production, and multi-Region delivery remain separately gated. Control Tower
and VPN/BGP are explicitly out of the current delivery scope.

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

**Selected milestone:** deliver the direct Organizations control plane under
[ADR 0019](adr/0019-direct-organizations-account-vending.md), while preserving
the completed isolated sandbox-network root under
[ADR 0018](adr/0018-sandbox-network-gitops-delivery.md). The broader legacy
state adoption in [ADR 0015](adr/0015-adopt-legacy-state-bootstrap.md) remains
independently gated. The new root is limited to the management account,
top-level OUs, baseline SCPs, its dedicated state backend, and account records
explicitly supplied in reviewed tfvars.

ADR 0018 authorizes only its versioned policy bootstrap and protected GitHub
workflow. ADR 0019 additionally authorizes the versioned management-account
CloudFormation control-plane bootstrap and the protected Organization GitOps
workflow. Neither authorizes a local Terraform apply, manual state change,
Control Tower launch, VPN/BGP, endpoint, workload, identity, data, production,
or multi-Region deployment. The sandbox-network delivery remains the only
completed Terraform infrastructure slice under this authority.

### Sandbox-network reconciliation record

The first GitHub apply stopped on explicit least-privilege IAM denials after
creating partial state. Two reviewed, root-specific CloudFormation policy
updates then let Terraform reconcile that same remote state. The final
[protected apply run](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35515450999)
succeeded, and the immediate manual
[drift check](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35515764460)
reported no changes. No console deletion, manual state edit, or ad hoc AWS
resource creation was used.

### Verified sandbox-network resources

Read-only AWS inspection after the successful apply confirmed:

- VPC `vpc-0073d0ec58988246b`, CIDR `10.64.0.0/16`, state `available`;
- VPC encryption control `enforce` and `available`;
- two private, non-public subnets: `10.64.0.0/20` in `us-east-2a` and
  `10.64.16.0/20` in `us-east-2b`;
- only local route targets, no endpoints, and a deny-all default security
  group;
- an `ACTIVE` all-traffic VPC Flow Log to the dedicated KMS-encrypted,
  365-day CloudWatch Log Group; and
- the dedicated KMS alias and Flow Log delivery role/policy.

The read-only evidence helper is
[`scripts/inspect-sandbox-network.sh`](../scripts/inspect-sandbox-network.sh).

## Delivery lanes

| Lane | Role | Do not treat it as |
|---|---|---|
| [`terraform/`](../terraform/README.md) | Candidate canonical Terraform delivery source; ADRs 0018 and 0019 are its initialized-backend exceptions. | Proof that any AWS resource exists before the GitHub run evidence. |
| [`docs/`](README.md) | Current decisions, prerequisites, runbooks, and delivery contracts. | Evidence that AWS services are deployed. |
| [`automation/terraform-pipelines/`](../automation/terraform-pipelines/README.md) | Reviewed reusable workflow source for future roots. | The active ADR 0018 and ADR 0019 root-specific delivery workflows. |
| Root [`modules/`](../modules/README.md) and [`roots/`](../roots/README.md) | Disabled historical prototypes retained as forensic input. | A deployment path. |
| [`docs/book/`](book/README.md) | Explanatory design reference. | Status, approval, or implementation authority. |
| [`docs/reviews/archive/`](reviews/archive/README.md) | Historical point-in-time assessments. | A current backlog or current repository state. |

## Next milestone and stop conditions

1. Preserve the apply, CloudTrail, dedicated-state, and weekday-drift evidence
   for the completed sandbox network.
2. Bootstrap the dedicated Organization state backend and configure GitHub's
   `landing-zone` environment protection; correct and prove the standard OIDC
   trust subject; then review the OU/SCP-only plan.
3. Keep account email/CIDR-dependent vending, production networking,
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
