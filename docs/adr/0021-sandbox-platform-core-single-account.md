# ADR 0021: Deliver a bounded single-account sandbox platform core

**Status:** Accepted — stakeholder requested immediate delivery without new
AWS accounts or email aliases.
**Decision date:** 2026-09-21

## Context

The current available delivery target is sandbox account `448871779014`. The
isolated `10.64.0.0/16` VPC, its two private subnets, VPC Flow Logs, GitHub OIDC
roles, encrypted remote backend, and protected `dev` environment already exist.
The requested production account set cannot be vended yet because distinct,
verified account email addresses are unavailable. Waiting for that dependency
would leave no application foundation running.

## Decision

1. Create a separate Terraform root at
   [`terraform/roots/sandbox-platform/us-east-2/dev`](../../terraform/roots/sandbox-platform/us-east-2/dev).
   It is pinned to sandbox account `448871779014` in `us-east-2` and owns only
   `gitops/sandbox-platform/us-east-2/dev/terraform.tfstate`.
2. The root consumes, but does not recreate or change the CIDR of,
   `sandbox-network-dev`. It requires two tagged private subnets and route
   tables and adds only S3/DynamoDB gateway endpoints plus ECR API/DKR, Logs,
   Secrets Manager, SSM, SSM Messages, and STS interface endpoints. No NAT or
   public subnet is introduced.
3. The root provisions an immutable, scan-on-push ECR repository; an ECS
   cluster with enhanced Container Insights; a 365-day application log group;
   a deletion-protected, PITR-enabled DynamoDB session table, ECR registry, and
   application log group encrypted by a dedicated rotating customer-managed KMS
   key; and a protected Cognito Essentials primary user pool. It creates no
   application task, public endpoint, OAuth callback client, or custom domain.
4. The versioned CloudFormation policy stack in
   [`bootstrap/sandbox-platform-delivery-policy`](../../bootstrap/sandbox-platform-delivery-policy/)
   attaches only root-specific state and service permissions to the existing
   sandbox GitHub OIDC roles. GitHub uses a pull-request plan, protected manual
   `dev` apply, and weekday non-remediating drift workflow. No long-lived AWS
   credential is stored in source or GitHub.

## Consequences

- This is a **single-account, single-Region reference platform**, not the
  original multi-account landing zone or a production deployment.
- It is immediately useful for private image delivery, ECS task deployment,
  Cognito configuration, and session storage once an image and approved
  application URL exist.
- It does not satisfy active-active Regional application delivery, Cognito
  MRR, DynamoDB global tables, Transit Gateway inter-Region routing, account
  isolation, public ingress, or VPN/BGP. Those need a non-overlapping second
  CIDR, app/domain inputs, and the future account contracts.
- The state, IAM permissions, and workflow are isolated from ADR 0018's VPC
  root. A failure or rollback in this root cannot modify its remote state.

## Alternatives rejected

1. **Wait for new accounts and email aliases.** Rejected for this immediate
   sandbox delivery; the production account boundary remains required later.
2. **Use administrator credentials or a local Terraform apply.** Rejected:
   the protected OIDC workflow is the auditable deployer.
3. **Create a public app without image/domain inputs.** Rejected: it would
   produce an unreachable or misleading endpoint and invent application
   security decisions.
