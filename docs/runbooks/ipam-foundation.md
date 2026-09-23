# IPAM foundation delivery

## Scope and current boundary

This runbook describes the future GitOps sequence for organization-managed VPC
IPAM. Both roots are currently under `infra/candidates/`; they have **no**
plan, apply, or drift workflow and must not be applied locally. It is not
evidence that an IPAM, pool, RAM share, or workload VPC allocation exists.

The implementation deliberately separates the AWS Organizations management
account prerequisite from Network-account resource ownership:

```text
Management account
  foundation/region-a/ipam-organization-admin
    └─ enable RAM organization sharing + delegate IPAM administration

Network account (IPAM home Region)
  network/region-a/ipam
    └─ IPAM → enterprise pool → Regional pools → constrained RAM shares

Workload account
  workload-*/region-{a,b}/...
    └─ reviewed regional pool ID in vpc.ipv4_ipam_pool_id
```

## Required approvals and inputs

Do not promote either root until the change record contains all of the
following:

- Management and Network account IDs, with the Network account approved as the
  VPC IPAM delegated administrator.
- The selected, distinct primary/secondary Region pair and its home Region.
- An enterprise-approved non-overlapping top-level CIDR, Regional child CIDRs,
  VPC allocation netmask policy, and workload-account/OU sharing list.
- Confirmation that AWS RAM sharing with AWS Organizations is permitted, plus
  a cost owner for IPAM Advanced.
- Dedicated state keys, least-privilege OIDC plan/apply/drift roles, a protected
  environment, and an approved candidate-to-active ADR/root promotion.

The `10.128.0.0/9` values in the example file are assumptions only and cannot
be copied into an apply without the enterprise overlap approval.

## Future protected delivery order

1. Promote and protect a management-account workflow for
   `foundation/region-a/ipam-organization-admin`; review its plan. It enables
   RAM organization sharing and registers the approved Network account as VPC
   IPAM delegated administrator.
2. After the management apply and read-only Organizations/IPAM evidence,
   promote and protect the Network-account home-Region workflow for
   `network/region-a/ipam`; review the hierarchy, Regional pool CIDRs, and RAM
   principal changes.
3. Apply the Network root only through its protected GitHub OIDC environment.
   Wait for IPAM pools and pool CIDRs to reach their AWS-managed ready state;
   IPAM provisioning can be asynchronous.
4. Record the exact `regional_pools.<key>.id` outputs in a reviewed workload
   root configuration as `workload.vpc.ipv4_ipam_pool_id`. Do not add a
   Terraform `remote_state` data source between account roots; the reviewed
   configuration change is the ownership and promotion boundary.
5. Plan the workload VPC root. Confirm it allocates from the intended Regional
   pool, has no default Internet/TGW route, and, when required, uses only its
   dedicated transit attachment subnets.
6. Collect post-apply evidence: delegated-admin record, RAM share/principals,
   IPAM pool/cidr status, workload VPC CIDR allocation, Flow Logs, and a
   no-change drift run. Stop on any unexpected CIDR, account, or route.

## Rollback and stop conditions

Stop before apply if the selected Regions are not distinct, an ASN/CIDR
overlaps any approved network, a RAM principal is not an approved account or
Organizations scope, IAM policy is broader than the target root, or a plan
changes an existing pool/allocation unexpectedly.

Do not delete an IPAM pool containing allocations to work around a failure.
First remove downstream VPC allocations through reviewed destroys/migrations,
then use a separately approved reverse-order change. Preserve plan, CloudTrail,
and allocation evidence with the change record.
