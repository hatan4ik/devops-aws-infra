# First delivery slice: foundation readiness and isolated sandbox-network delivery

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
3. **Activate the reviewed isolated-network delivery lane.** ADR 0017's
   GitHub OIDC trust is live. Manage ADR 0018's root-specific policy through
   the Terraform sandbox-delivery IAM root, configure non-secret role ARNs,
   then produce the first authoritative sandbox-network plan.
4. **Deliver the approved sandbox network.** With approved sandbox account,
   Region, CIDR, availability-zone, and state-key inputs now recorded, run the
   manual protected `dev` apply after review. The VPC remains private and
   isolated; this does not authorize a TGW, VPN/BGP, endpoint, workload, or
   landing-zone deployment.

## Explicit non-goals

- No AWS Organizations, Control Tower, account-vending, Transit Gateway, VPN,
  workload, ECS, Cognito, DynamoDB, edge, production network, or multi-Region
  deployment is created by this slice.
- No remote Terraform state is edited manually. Do not use `state mv`,
  `state rm`, or `import` outside the approved declarative adoption procedure.
- No credential, production value, Control Tower configuration, or shared
  network input is committed. ADR 0018 is the narrow exception that commits a
  sandbox-only account/Region/CIDR and non-secret dedicated backend key as
  immutable deployment configuration.

## Required evidence and acceptance criteria

| Deliverable | Acceptance evidence | Stop condition |
|---|---|---|
| Landing-zone evidence package | Every external-checklist row has a named owner, approved value, and change-record attachment. | Any account, Region, CIDR/ASN, governance, security, DNS, quota, or budget input is unresolved. |
| Legacy state adoption | Protected backup digest/version ID; inactive lock check; approved no-change plan; declarative migration; refresh-only plan; restore drill; Cloud Architecture, Security, SRE, and FinOps records. | Active lock, resource-changing plan, missing approval, or failed backup/restore validation. |
| Pipeline control proof | Repository rules, GitHub environments, SHA-pinned workflow source, isolated plan/apply/drift OIDC role evidence, and a sandbox plan-only run. | Any shared role, unprotected environment, mutable action reference, or apply permission in the plan job. |
| Sandbox network delivery | Approved account/Region/CIDR/state key, authoritative backend, policy/security scan, reviewed plan, protected manual apply, and weekday drift detection. | Plan differs from the isolated scope or lacks policy/security/rollback evidence. |

## Safe local verification

The following validates the candidate source without AWS credentials or a
backend. It is not a deployment command:

```sh
scripts/validate-terraform-quality.sh
scripts/verify-adr-boundary.sh
```

## Transition to the next slice

The platform may proceed to a separately reviewed shared-network or landing-zone
decision only after the sandbox delivery evidence is complete. The sandbox
approval never implies a production, TGW, VPN/BGP, application, or multi-Region
apply.
