# First delivery slice: foundation readiness and one sandbox-network plan

**Status:** selected delivery sequence; execution gated.

## Objective

Turn the repository from reviewed design into a safe, evidence-backed delivery
starting point without claiming that the entire multi-account, multi-Region
platform is ready. This slice deliberately ends before any application,
production identity, data-plane, or multi-Region traffic deployment.

## Scope and order

1. **Validate the landing-zone inputs.** Complete the organization, identity,
   network, security, DNS, CI/CD, FinOps, workload, and Region evidence in the
   [external verification checklist](../architecture/external-verification.md).
   Assign accountable owners and attach the evidence to one change record.
2. **Adopt the legacy state bootstrap.** Use the transitional
   [`bootstrap-state`](../../terraform/roots/foundation/region-a/bootstrap-state/)
   root and the [adoption runbook](../runbooks/adopt-legacy-state-backend.md)
   only after its state backup, inactive-lock, no-resource-change-plan,
   specialist-approval, and cost-owner gates are met. This is a state-address
   migration, not a rebuild or hardening apply.
3. **Prove delivery controls without mutation.** In a dedicated approved
   pipeline repository, create separate environment-scoped GitHub OIDC plan,
   apply, and drift roles. Run the credential-free quality workflow first, then
   a sandbox **plan-only** workflow. The sources in
   [`automation/terraform-pipelines/`](../../automation/terraform-pipelines/README.md)
   are templates until that repository and its protections exist.
4. **Produce one sandbox network-root plan.** With approved account ID, Region,
   CIDR/IPAM allocation, ASN/prefix plan, and required endpoint/DNS inputs,
   generate and review an authoritative backend plan for a single sandbox
   network root. A plan is an acceptance artifact, not permission to apply.

## Explicit non-goals

- No AWS Organizations, Control Tower, account-vending, Transit Gateway, VPN,
  workload VPC, ECS, Cognito, DynamoDB, edge, production network, or
  multi-Region deployment is created by this slice.
- No remote Terraform state is edited manually. Do not use `state mv`,
  `state rm`, or `import` outside the approved declarative adoption procedure.
- No OIDC trust, GitHub environment, secret, real backend configuration,
  account ID, CIDR, ASN, or production value is committed to this repository.

## Required evidence and acceptance criteria

| Deliverable | Acceptance evidence | Stop condition |
|---|---|---|
| Landing-zone evidence package | Every external-checklist row has a named owner, approved value, and change-record attachment. | Any account, Region, CIDR/ASN, governance, security, DNS, quota, or budget input is unresolved. |
| Legacy state adoption | Protected backup digest/version ID; inactive lock check; approved no-change plan; declarative migration; refresh-only plan; restore drill; Cloud Architecture, Security, SRE, and FinOps records. | Active lock, resource-changing plan, missing approval, or failed backup/restore validation. |
| Pipeline control proof | Repository rules, GitHub environments, SHA-pinned workflow source, isolated plan/apply/drift OIDC role evidence, and a sandbox plan-only run. | Any shared role, unprotected environment, mutable action reference, or apply permission in the plan job. |
| Sandbox network plan | Approved account/Region/CIDR/ASN inputs, authoritative backend, policy/security scan, cost diff, reviewed plan, rollback and stop condition. | Plan differs from the approved scope or lacks cost/security/rollback evidence. |

## Safe local verification

The following validates the candidate source without AWS credentials or a
backend. It is not a deployment command:

```sh
scripts/validate-terraform-quality.sh
scripts/verify-adr-boundary.sh
```

## Transition to the next slice

The platform may proceed only after all four acceptance rows are complete and
the change record is approved. The next decision is then whether to authorize
the reviewed sandbox network apply. It requires a separate approval; it is not
implied by this document or by a successful plan.
