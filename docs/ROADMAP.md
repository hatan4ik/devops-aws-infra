# Platform roadmap

The repository contains a private single-account Sandbox design, but the
application plane is currently absent. The target remains an AWS-native,
US-only, multi-account, multi-Region platform for low-latency applications and
large authenticated user populations. This is a sequence of approval gates,
not executable Terraform source. See the
[architecture overview](ARCHITECTURE.md) for the current inventory and target.

## Current baseline

- Existing AWS Organization with the six approved OUs, IAM Identity Center in
  `us-east-1`, and three accounts that still need approved OU placement.
- GitHub OIDC delivery design, isolated Terraform state, and root-specific
  plan/apply/drift workflow contracts.
- No currently observed Terraform-tagged sandbox VPC, ECS cluster, Cognito
  pool, ECR repository, or Transit Gateway. The Sandbox application plane was
  intentionally torn down and must be rebuilt only through GitOps.
- Provider-backed TGW three-phase routing, Cognito MRR adoption, and static
  edge blueprint code now exist in their owning module repositories. They are
  not signed releases, active-root pins, plans, or deployed infrastructure.

## Next controlled stages

1. **Root and Organization adoption.** Enable and verify management root MFA,
   then approve Terraform imports and OU placement for the existing Identity
   delegated-admin and Sandbox member accounts. Review the stricter live
   root-SCP regional policy before any `us-west-2` plan.
2. **Minimal account and network foundation.** Approve the supplied root-email
   inputs for Security/Audit and Log Archive accounts, plus an explicitly
   supplied unique Network-account email. Approve the IPAM overlap check, TGW
   route matrix, RAM share scope, and tested US-only SCP replacement before any
   spoke VPC is created.
3. **Central security and cost foundation.** Approve ownership, central
   logging, Config aggregation, security-service delegation, a $500 initial
   budget, alert recipients, and cost tags. Use a reviewed plan; do not infer
   values or create accounts manually.
4. **Sandbox rebuild and service-module migration.** Pin approved immutable
   module releases, review network/platform/workload plans, and apply only
   through the ordered GitHub workflow path.
5. **Public application decision.** Approve a domain owner, DNS, OAuth callback
   URLs, application SLOs, and rollback design; publish a signed edge-blueprint
   release and create an isolated active root before exposing an application.
6. **Hybrid connectivity.** Obtain on-premises ASNs, two customer-gateway IPs
   per Region, accepted prefixes, tunnel ownership, and monitoring. Deploy
   Site-to-Site VPN/BGP only after the Network foundation exists.
7. **Second Region and production.** Validate latency, quotas, data residency,
   Cognito eligibility and matching multi-Region KMS key replicas; release and
   adopt ADR 0024's MRR submodule with an `INACTIVE` secondary; then validate
   authentication, replication/data recovery, capacity, observability,
   game-day evidence, and cost acceptance before activation or production.

Every stage requires a decision record where the architecture changes, a new
root-specific OIDC role/workflow where the delivery boundary changes, a
reviewed plan, protected apply, and post-apply drift evidence.
