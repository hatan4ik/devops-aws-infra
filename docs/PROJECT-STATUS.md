# Project status and delivery authority

**Status as of 2026-09-22:** the isolated ADR 0018 sandbox network and the ADR
0019 direct Organizations control plane have been delivered through protected
GitHub OIDC workflows and verified read-only in AWS. The control plane owns a
dedicated encrypted state backend, six top-level OUs, two baseline SCPs, and
12 policy attachments. It has vended **no** account and has not moved an
existing account. ADR 0021 now supplies the reviewed single-account sandbox
platform core delivery lane; it is source until its protected GitHub apply and
read-only verification succeed. ADR 0022 source is ready to transfer sandbox
OIDC/provider/role/policy ownership from the three historical CloudFormation
stacks into Terraform; that live handoff has not yet been applied. It is not a
production, multi-account, or multi-Region platform. Control Tower and VPN/BGP
remain out of current scope.

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

**Completed milestones:** the direct Organizations control plane under
[ADR 0019](adr/0019-direct-organizations-account-vending.md) and the isolated
sandbox-network root under [ADR 0018](adr/0018-sandbox-network-gitops-delivery.md).
The broader legacy-state adoption in
[ADR 0015](adr/0015-adopt-legacy-state-bootstrap.md) remains independently
gated. The Organization root is limited to the management account, top-level
OUs, baseline SCPs, its dedicated state backend, and account records explicitly
supplied in reviewed tfvars.

ADR 0022 replaces sandbox CloudFormation policy/bootstrap ownership with a
Terraform-owned identity root. ADR 0019 additionally authorizes the versioned management-account
CloudFormation control-plane bootstrap and protected Organization GitOps
workflow. ADR 0021 authorizes a distinct, single-account sandbox platform
root. No ADR authorizes a local Terraform apply, manual state change, Control
Tower launch, VPN/BGP, member-account baseline, public ingress, production, or
multi-Region deployment without a separately reviewed root and plan.

### Sandbox-network reconciliation record

The first GitHub apply stopped on explicit least-privilege IAM denials after
creating partial state. Historical root-specific CloudFormation policy updates
then let Terraform reconcile that same remote state. ADR 0022 retires that
ownership after the controlled Terraform import. The final
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

### Organization control-plane delivery record

The [protected Organization apply](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35647498501)
completed after an explicit `landing-zone` environment approval. The immediate
[non-remediating drift run](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35647687340)
reported no change.

Read-only Organization inventory confirmed:

- top-level OUs: `Security`, `Platform`, `Workloads-Production`,
  `Workloads-NonProduction`, `Sandbox`, and `Suspended`;
- customer SCPs `platform-deny-organization-escape` and
  `platform-deny-unapproved-regions`, attached 12 times (both policies to all
  six OUs), never to the Organizations root;
- the KMS-encrypted Object-Lock state object at
  `gitops/organization/global/terraform.tfstate`; and
- exactly the original three active accounts. No account is present in the
  `accounts` Terraform map, so none was created or moved.

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
   for the completed sandbox network and Organization control plane.
2. Deliver and verify ADR 0021's private sandbox platform core through its
   dedicated GitHub OIDC workflow.
3. Supply the container image, approved public domain/Route 53 and ACM owner,
   OAuth callback/logout URLs, and Cognito email/SMS ownership before public
   ingress or an ECS service is created.
4. Add explicit Network, Shared Services, Log Archive, Security/Audit, and
   Production account email/owner/OU contracts; then review the account-vending
   plan. Do not infer aliases.
5. Obtain an enterprise IPAM supernet and route-domain matrix, including a
   non-overlapping second-Region CIDR, before TGW or multi-Region delivery.

Stop immediately if the backend lock is active, a plan includes resources
outside its reviewed ADR/root, the caller is not the intended account, a
policy/bootstrap value differs from source, or required run evidence is absent.
Do not work around an exception with manual state commands or console changes.

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
