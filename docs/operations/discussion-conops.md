# AWS Platform ConOps — Discussion Reference

## Purpose

Operate a secure, repeatable AWS platform through GitOps. Terraform is the
only desired-state authority; GitHub Actions with short-lived AWS OIDC roles is
the only deployment path. Humans use IAM Identity Center only for inspection
and approved break-glass recovery—not local Terraform applies or console
changes.

## Current truth

The delivered scope is a **single-account, private sandbox in `us-east-2`**:

- `10.64.0.0/16` VPC across two private Availability Zones, no Internet
  Gateway, NAT gateway, or public task IPs;
- VPC Flow Logs; S3 and DynamoDB gateway endpoints; and private interface
  endpoints for STS, SSM, Secrets Manager, ECR, CloudWatch Logs, and Cognito;
- ECR with immutable image tags and image scanning; ECS Fargate cluster;
  Cognito user pool/client; KMS-encrypted logs; and DynamoDB session storage;
- separate remote Terraform state and scoped GitHub OIDC roles for delivery,
  network, platform, and workload roots.

The private auth-demo service is a deployment in progress, not yet operational
evidence. It is ready only when its protected workload apply succeeds, ECS has
`runningCount == desiredCount`, tasks are healthy, logs are clean, and a
subsequent plan reports no unexpected change.

## Deliberately not deployed

Transit Gateway, cross-account attachments, VPN/BGP, Control Tower, public
ALB/API, Route 53 customer DNS, ACM, WAF, customer-facing secrets, a second
Region, and disaster recovery have **not** been deployed. They require an
approved design and their own Terraform roots; they must not be represented as
current capability.

## Who does what

| Actor | Responsibility | Boundary |
|---|---|---|
| Platform team | Terraform roots, module pins, CI/CD contracts, evidence | Cannot bypass PR review or protected environment approval. |
| Application team | Immutable image digest, health endpoint, task configuration, secret ARNs, rollback digest | Cannot alter network, OIDC trust, or platform IAM. |
| Security | Approves least privilege, exposure, domains, and production controls | Must not treat a static scan as live proof. |
| On-call | Inspects CloudTrail, ECS events/logs, Flow Logs, alarms, and drift | Does not make unrecorded console changes. |

## Repeatable setup and deployment order

1. Bootstrap human IAM Identity Center access and GitHub OIDC roles once, as
   documented in [AWS access bootstrap](../runbooks/bootstrap-aws-access.md)
   and [GitHub OIDC bootstrap](../runbooks/github-oidc-bootstrap.md).
2. Apply only through reviewed roots, in this order:
   `sandbox-delivery-iam` → `sandbox-network` → `sandbox-platform` → publish
   the immutable application image → `sandbox-workload`.
3. Make every change in Terraform or a versioned external module. Roots pin
   reusable `aws.modules.*` repositories to a full commit SHA.
4. Open a pull request, review the root-specific Terraform plan and quality
   checks, merge to protected `main`, then dispatch the matching protected
   apply workflow with `confirm=apply`.
5. Prove the result with ECS health/logs and a no-change plan or drift run;
   record the workflow and operational evidence.

```bash
gh workflow run sandbox-delivery-iam-apply.yml --ref main -f confirm=apply
gh workflow run sandbox-network-apply.yml --ref main -f confirm=apply
gh workflow run sandbox-platform-apply.yml --ref main -f confirm=apply
gh workflow run sandbox-workload-apply.yml --ref main -f confirm=apply
```

## Security rules that do not change

- No static AWS keys in GitHub, source, Terraform state, or tfvars.
- No public traffic or broad `0.0.0.0/0` egress without a separately approved
  Terraform design.
- Tasks use private endpoint paths; the ECR image-layer path additionally uses
  the AWS-managed regional S3 prefix list, rather than public internet access.
- Every workload uses immutable image digests, separate task/execution roles,
  encrypted logging, minimum IAM, and deployment rollback controls.
- Terraform state and live AWS are never manually altered to “make it work.”

## Definition of done for a workload

`merged PR` + `approved GitHub apply` + `ECS stable` + `healthy task/log proof`
+ `post-apply no-change plan/drift result`.

For the fuller operating model, ownership model, onboarding contract, and
incident recovery procedure, see the [Platform ConOps](conops.md).
