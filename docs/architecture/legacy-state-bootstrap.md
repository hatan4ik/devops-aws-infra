# Legacy state bootstrap inventory

**Status:** Observed 2026-09-19; disposition decision required.
**Scope:** A legacy bootstrap in `us-east-2`; it is not managed by the
canonical [`terraform/`](../../terraform/README.md) delivery tree.

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
the resource-disposition decision is pending.

## Required decision

The platform owner must choose one path and record it in an ADR amendment:

1. **Adopt:** import the bootstrap into an approved canonical foundation root,
   assign an operational owner, and add state restore, cost, and lifecycle
   controls.
2. **Retire:** approve a deliberate destruction plan after confirming the
   retained state is no longer needed and the Compliance Object Lock retention
   period has elapsed.

Neither path is authorized by this inventory document.
