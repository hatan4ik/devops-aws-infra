# Project status and delivery authority

**Status as of 2026-09-22:** the isolated ADR 0018 sandbox network, ADR 0019
direct Organizations control plane, sandbox delivery identity, and ADR 0021
single-account sandbox platform core have been delivered through protected
GitHub OIDC workflows. The live baseline includes a private VPC and endpoints,
an ECS cluster, immutable ECR repository, Cognito user pool/client, KMS data
key, DynamoDB session table, and dedicated state keys. The first private
`auth-demo` workload has a Terraform-owned service, task definition, roles,
security group, encrypted log group, and immutable ECR image. It is not called
operational until the protected workload reconciliation completes and ECS
reports healthy tasks at the desired count. There is no public ingress,
production workload, account vending, multi-account routing, Transit Gateway,
VPN/BGP, or multi-Region failover. The control plane owns a dedicated encrypted
state backend, six top-level OUs, two baseline SCPs, and 12 policy attachments.
It has vended **no** account and has not moved an existing account. ADR 0022
has transferred sandbox OIDC/provider/role/policy ownership into Terraform, and
the three historical CloudFormation stacks have been retired with retained IAM
resources. Control Tower remains out of current scope.

## Start here

This document is the current operating status. Read it before a design chapter,
review snapshot, or Terraform directory.

| Question | Authoritative location |
|---|---|
| What is true now and what happens next? | This status document |
| Which architecture decision controls a change? | [ADR index](adr/README.md) |
| Which Terraform tree may be executed by GitHub? | [`infra/active/`](../infra/README.md) only |
| What is the first bounded delivery slice? | [First delivery slice](delivery/first-delivery-slice.md) |
| What evidence is required before an AWS apply? | [External verification checklist](architecture/external-verification.md) |
| How is the selected legacy backend adopted safely? | [Adoption runbook](runbooks/adopt-legacy-state-backend.md) |
| What is the credential-free quality evidence? | [Terraform quality workflow](../.github/workflows/terraform-quality.yml) |

## Current delivery decision

**Completed milestones:** the direct Organizations control plane under
[ADR 0019](adr/0019-direct-organizations-account-vending.md), the isolated
sandbox-network root under [ADR 0018](adr/0018-sandbox-network-gitops-delivery.md),
the Terraform-owned sandbox delivery identity handoff under
[ADR 0022](adr/0022-terraform-owned-sandbox-delivery-identity.md), and the
single-account private sandbox platform core under
[ADR 0021](adr/0021-sandbox-platform-core-gitops-delivery.md).
The broader legacy-state adoption in
[ADR 0015](adr/0015-adopt-legacy-state-bootstrap.md) remains independently
gated. The Organization root is limited to the management account, top-level
OUs, baseline SCPs, its dedicated state backend, and account records explicitly
supplied in reviewed tfvars.

ADR 0022 replaces sandbox CloudFormation policy/bootstrap ownership with a
Terraform-owned identity root. ADR 0019 additionally authorizes the versioned
management-account CloudFormation control-plane bootstrap and protected
Organization GitOps workflow. ADR 0021 authorizes a distinct, single-account
sandbox platform root. No ADR authorizes an unreviewed local Terraform apply,
manual state change, Control Tower launch, VPN/BGP, member-account baseline,
public ingress, production, or multi-Region deployment without a separately
reviewed root and plan. A narrowly reviewed platform state recovery included an
encrypted pre-change backup, active-lock inspection, and zero-taint verification;
it is not a general local delivery path. Normal delivery is through GitHub OIDC.

The private `sandbox-workload` root, delivery-IAM policy releases, protected
role variables, dedicated remote state, and plan/apply/drift workflows are
active. Its reviewed `auth-demo` entry supplies an immutable image digest,
private task contract, health check, CPU target tracking from two to twelve
tasks, and a Cognito authorization-code client limited to a local HTTPS callback.
It creates neither a public endpoint nor a customer authentication journey.

### Sandbox delivery identity handoff record

The ADR 0022 root imported the existing GitHub OIDC provider, six scoped roles,
four delivery policies, and six existing attachments. It added two bounded
identity-delivery policies and their three reviewed attachments. The three
historical CloudFormation stacks were then updated with `Retain` metadata and
deleted; the archive remains evidence only. The protected
[OIDC plan](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35661197443)
reported **no changes**, and the protected
[detailed-exitcode drift run](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35661534659)
also reported no change. After the backend KMS correction, the latest protected
[OIDC plan](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35663753243)
again reported **no changes**, and the latest protected
[detailed-exitcode drift run](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35663756348)
also reported no change. The active state is a versioned, customer-KMS-encrypted
object at `gitops/sandbox-delivery/us-east-2/global/terraform.tfstate`; its
prior SSE-S3 version remains preserved.

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

### Sandbox-platform reconciliation record

The protected [platform apply](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35732702897)
reconciled the remaining KMS alias and endpoint security-group rule after its
least-privilege policy was updated through the sandbox-delivery Terraform root.
The subsequent ECS-module ownership correction removed conflicting inline and
standalone security-group ingress management. Its protected
[platform plan](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35733786879)
reported **no changes**. The platform's Terraform state recovery, performed
before the apply, was limited to clearing two confirmed stale taints after an
encrypted versioned-state backup and active-lock check; no resource was
destroyed and the final tainted-resource count was zero.

The verified platform root owns the private interface endpoints, ECS cluster
and ECR repository, Cognito user pool, KMS data key and alias, and DynamoDB
session table with point-in-time recovery and TTL. ECS tasks and services are
intentionally owned by the separate `sandbox-workload` root. Neither root
creates a public route, load balancer, customer domain, second Region, transit
gateway, or VPN.

The protected [Cognito endpoint apply](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35740951565)
created the private `cognito-idp` interface endpoint required by no-NAT
workloads. The protected [workload apply](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35741133187)
initialized the separate workload state and recorded only its then-empty
Terraform contract. The cited post-apply
[platform reconciliation plan](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35741234693)
and [workload reconciliation plan](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35741238997)
both reported **no changes**.

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
| [`infra/active/`](../infra/README.md) | The only Terraform source referenced by root GitHub delivery workflows. | Proof that a workflow has run or an AWS resource exists. |
| [`infra/candidates/`](../infra/README.md#candidates) | Future foundation, network, TGW, and workload source. | A deployment path. |
| [Versioned module repositories](MODULE-REPOSITORIES.md) | Reusable `aws.modules.*` implementation, released independently and selected by immutable source commit. | A root, an AWS apply record, or permission to upgrade a consumer. |
| [`docs/`](README.md) | Current decisions, prerequisites, runbooks, and delivery contracts. | Evidence that AWS services are deployed. |
| [terraform-pipelines](https://github.com/hatan4ik/terraform-pipelines) | Released reusable Terraform workflow library; consumers pin its immutable release commit. | The active root-specific delivery workflows or an AWS identity provider. |
| [`archive/pipeline-templates-bootstrap/`](../archive/pipeline-templates-bootstrap/) | Historical pre-release copy of the reusable workflow source. | A consumer source or active workflow. |
| [`bootstrap/`](../bootstrap/README.md) | One-time, reviewed Organization prerequisite template. | An active Terraform root or recurring deployment lane. |
| [`reference/`](../reference/README.md) | Read-only review inputs retained for traceability. | A dependency of Terraform, workflows, or an apply. |
| [`archive/prototypes/`](../archive/prototypes/) | Disabled historical modules and roots retained as forensic input. | A deployment path. |
| [`docs/book/`](book/README.md) | Explanatory design reference. | Status, approval, or implementation authority. |
| [`docs/reviews/archive/`](reviews/archive/README.md) | Historical point-in-time assessments. | A current backlog or current repository state. |

## Next milestone and stop conditions

1. Complete the protected workload reconciliation and record ECS stability,
   container health, log evidence, and a no-change workload plan before calling
   `auth-demo` operational.
2. Supply an approved public domain/Route 53 and ACM owner, OAuth
   callback/logout URLs, and Cognito email/SMS ownership before public ingress.
3. Add explicit Network, Shared Services, Log Archive, Security/Audit, and
   Production account email/owner/OU contracts; then review the account-vending
   plan. Do not infer aliases.
4. Obtain an enterprise IPAM supernet and route-domain matrix, including a
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
