# Runbook: account decommission

## Scope and guardrails

Use after a workload has been migrated or retired and the account owner has
approved closure. This is not an automated Terraform operation. AWS account
closure, retention, legal hold, security evidence, and billing obligations are
external control-plane actions that require the organization's account-vending
owner and security/finance approval.

## Procedure

1. Open a decommission change record identifying the account, owner, data
   classification, retention/legal-hold decision, replacement account or
   service, and target closure date. Freeze non-emergency deployments.
2. Inventory resources, identities, KMS keys, Secrets Manager secrets,
   DNS/certificates, VPC/TGW/RAM links, VPN/BGP advertisements, delegated
   administrator registrations, budgets, and external dependencies. Revoke
   cross-account grants only after a dependency owner signs off.
3. Export required audit/security records to the approved Log Archive and
   validate retention. Preserve Terraform state and its restore evidence;
   never delete a state backend merely because a workload account is retiring.
4. Drain traffic, remove DNS/Global Accelerator eligibility through an approved
   change, and verify no client, on-premises route, scheduled job, or data
   replication path still targets the account. Exercise rollback before delete
   actions where a controlled disable is available.
5. Remove workload resources through their approved delivery source, validate
   bill and CloudTrail quiet periods, then follow the Control Tower/AFT account
   closure process. Do not use a console bulk delete as a substitute for
   evidence-backed decommissioning.

## Completion evidence

Retain approvals, dependency inventory, archive locations/retention, route and
DNS withdrawal evidence, state location, final Cost Explorer allocation,
closure request ID, and post-closure verification. Update the account registry
and ownership documentation only after the control plane confirms closure.
