# Runbook: planned regional evacuation

## Purpose

Use for an approved, planned withdrawal from a Region, not an incident
failover. The operational goal is to remove a Region without silently changing
data residency, identity, routing, or on-premises connectivity. For an active
outage, use [regional application failover](regional-failover.md).

## Preconditions

The Cloud Architect, Security Engineer, Network Engineer, SRE, service owner,
and data owner must approve the target architecture. Record the source and
survivor Regions, data-residency decision, application capacity/quotas,
identity behaviour, client cutover plan, DNS/Global Accelerator policy, TGW
and VPN/BGP prefixes, rollback date, and all dependencies. A successful staged
game day is required before production withdrawal.

## Controlled sequence

1. Establish healthy replacement capacity and service quotas; validate private
   endpoints, KMS/secrets, observability, backup/restore, authentication, and
   authorization in the survivor Region.
2. Migrate or retire data using the approved data-specific runbook. Prove
   replication/restore consistency and retention before moving traffic. Never
   use a traffic cutover to mask an untested data migration.
3. Gradually drain edge and API traffic through the approved route policy;
   validate synthetics, SLOs, user sign-in, authorization allow/deny, and
   on-premises paths at every step. Preserve a documented rollback route until
   the agreed stability window has passed.
4. Withdraw TGW, RAM, VPN/BGP, DNS, endpoint, and monitoring dependencies only
   after traffic and data evidence shows no remaining use. Changes must be
   committed through approved delivery sources, not untracked console edits.
5. Decommission regional workload resources through the account-decommission
   procedure where applicable, retain state/backup evidence, and update the
   approved Region allow-list and disaster-recovery plan.

## Completion evidence

Keep capacity/quotas proof, change approvals, data integrity/restore results,
traffic and identity tests, route withdrawals, rollback decision, cost impact,
and post-evacuation incident review. Do not claim a Region is evacuated while
any active VPN/BGP prefix, client route, replication stream, or recovery
commitment still depends on it.
