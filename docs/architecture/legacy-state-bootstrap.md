# Legacy state bootstrap inventory

**Status:** Adoption selected 2026-09-19; canonical state-address migration pending.
**Scope:** A legacy bootstrap in `us-east-2`; it is represented by the
transitional canonical [`bootstrap-state` root](../../terraform/roots/foundation/region-a/bootstrap-state/),
but the remote Terraform state has not yet been re-addressed.

## Confirmed resources

| Resource | Observed control state | Current purpose |
|---|---|---|
| S3 bucket `platform-tf-state-shared-f3ddb8cc` | Versioning, KMS encryption, all four public-access blocks, and 14-day Compliance Object Lock; one state object; no bucket policy | Legacy Terraform state storage |
| Customer-managed KMS key `alias/terraform-state-backend` | Enabled; annual rotation | State-bucket encryption |
| DynamoDB table `platform-tf-lock-table` | Active; pay-per-request billing | Legacy Terraform state locking |

The read-only inventory found no `us-east-2` EC2 instances, NAT gateways,
Transit Gateways, VPN connections, load balancers, ECS/EKS clusters, Lambda
functions, RDS instances, Cognito user pools, REST API Gateways, CloudFormation
stacks, CloudFront distributions, or Route 53 hosted zones. Discovery in most
other enabled Regions is explicitly denied by an AWS Organizations SCP, so this
is not a claim that those Regions are empty.

## Operating boundary

The root repository has no active AWS credential, plan, or apply workflow. The
legacy prototype roots are disabled and must not be used to alter these
resources. Do not delete state objects, KMS material, or the lock table while
the state-address migration and its evidence are pending.

## Adopted disposition

The Platform Owner selected adoption in [ADR 0015](../adr/0015-adopt-legacy-state-bootstrap.md).
The canonical source mirrors the observed bootstrap and protects the bucket,
KMS key, and lock table from Terraform destruction. It does not make an AWS
change by itself.

The next permitted action is the explicitly approved state-address migration in
the [adoption runbook](../runbooks/adopt-legacy-state-backend.md). It requires
a protected backup, active-lock check, a no-resource-change plan, named
specialist approvals, and recorded cost ownership. The later hardening change
must add a Log Archive destination, restrictive state/KMS policies, DynamoDB
deletion protection, cross-Region recovery, and a tested restore procedure.

Until that migration completes, the disabled prototype files remain forensic
evidence only and are not a deployment path.
