# Platform Concept of Operations (ConOps)

## Scope and current state

This ConOps governs the delivered single-account sandbox in `us-east-2` and
its progression to private ECS services. It is the operating model for source,
GitHub OIDC delivery, monitoring, recovery, and evidence. It is not authority
to deploy the future multi-account/multi-Region architecture; those roots stay
candidate-only until separately approved.

The current sandbox has a private VPC, flow logs, private AWS endpoints, ECR,
an ECS cluster, Cognito user pool/client, KMS data key, DynamoDB session table,
and dedicated Terraform state paths. `auth-demo` is the first private workload
composition. A service is considered operational only after its protected
workload apply and post-apply ECS stability check have succeeded; source or a
partially applied resource is never deployment evidence.

## Discussion quick reference

| Topic | Reference answer |
|---|---|
| What owns AWS? | Only roots in [`infra/active/`](../../infra/README.md), executed by protected GitHub Actions. Reusable logic lives in independently released `aws.modules.*` repositories and is pinned by full commit SHA. |
| Human and CI identity | Humans inspect through IAM Identity Center profiles. GitHub uses environment-scoped, short-lived OIDC roles—never static AWS keys. |
| Current private baseline | One `10.64.0.0/16` VPC, two private subnets in `us-east-2a/b`, Flow Logs, S3/DynamoDB gateway endpoints, STS/SSM/Secrets Manager/ECR/CloudWatch Logs/Cognito interface endpoints, ECR, ECS, Cognito, KMS, and DynamoDB. |
| How an application is delivered | App repository builds an immutable ECR digest through its own OIDC publisher role. A reviewed `applications` map in the workload root supplies that digest, size, health check, autoscaling, private network contract, and optional Cognito client. |
| How to prove it works | Required evidence is a green protected apply, ECS service `runningCount == desiredCount`, a passing task/container health check, CloudWatch logs, then a no-change plan or drift result. |
| What is deliberately absent | No public task IPs, internet gateway, NAT, public ALB/API, Route 53 customer domain, WAF, Transit Gateway, VPN/BGP, Control Tower landing zone, second Region, or production claim. |

## Setup and repeatable delivery order

1. Complete the one-time access prerequisites in
   [AWS access bootstrap](../runbooks/bootstrap-aws-access.md) and
   [GitHub OIDC bootstrap](../runbooks/github-oidc-bootstrap.md). Human access
   uses `AWS-hatan4ik-sandbox`; GitHub environment variables contain only
   root-specific role ARNs, never credentials.
2. Apply the roots in dependency order: `sandbox-delivery-iam`,
   `sandbox-network`, `sandbox-platform`, publish the application image, then
   `sandbox-workload`. Each root has an isolated state key and an apply role.
3. For every change, modify Terraform/module pins or the typed app map, open a
   PR, and review the root plan and quality checks. Merge only a clean plan.
4. Dispatch the matching `*-apply.yml` workflow from protected `main` with
   `confirm=apply`. The workflow re-plans `main` under OIDC before applying.
5. Run the root plan or drift workflow after apply and retain its evidence. Use
   the workload runbook for service health and rollback; use a prior immutable
   image digest for application rollback.

Common GitHub CLI dispatches, after merge and plan review:

```bash
gh workflow run sandbox-delivery-iam-apply.yml --ref main -f confirm=apply
gh workflow run sandbox-network-apply.yml --ref main -f confirm=apply
gh workflow run sandbox-platform-apply.yml --ref main -f confirm=apply
gh workflow run sandbox-workload-apply.yml --ref main -f confirm=apply
```

Read-only live checks use the sandbox SSO profile:

```bash
aws sts get-caller-identity --profile AWS-hatan4ik-sandbox
aws ecs describe-services --cluster sandbox-platform-dev-cluster \
  --services sandbox-workload-dev-auth-demo --region us-east-2 \
  --profile AWS-hatan4ik-sandbox
```

## Operators and responsibilities

| Role | Responsibility | Cannot do alone |
|---|---|---|
| Platform owner | Maintains roots, module pins, GitHub workflow contracts, and evidence. | Bypass protected environment approval or deploy an unreviewed plan. |
| Application owner | Supplies immutable image digest, task contract, health endpoint, non-secret configuration, secret ARNs, and OAuth URLs. | Alter VPC, OIDC trust, or delivery IAM policy. |
| Security owner | Approves task permissions, secret access, ingress, domains, and production exposure. | Treat a green static scan as live deployment evidence. |
| On-call/SRE | Reviews alarms, logs, CloudTrail, drift result, and rollback evidence. | Run a local Terraform apply or alter state without the recovery procedure. |

## Normal change lifecycle

1. Change an external module at its own release commit, or change one active
   root. Consumers pin the exact 40-character commit SHA.
2. Open a pull request. Credential-free quality and root-specific GitOps policy
   checks must pass. The matching root plan uses the scoped GitHub OIDC plan
   role and remote state lock.
3. Review the plan, cost/operational effect, and module upgrade boundary.
   Unexpected create, replace, destroy, broad IAM permission, public route, or
   account/Region mismatch is a stop condition.
4. Merge to protected `main`. Dispatch only the matching root apply workflow,
   type `apply`, and obtain GitHub environment approval. The workflow re-plans
   `main` using its scoped OIDC apply role and applies that exact plan once.
5. Run the matching plan or drift workflow. Record a no-change plan, CloudTrail
   evidence, and the declared post-deploy checks before calling a change done.

## Application-service onboarding

The `sandbox-workload` root accepts a typed `applications` map. It can create
multiple private Fargate services with one module call; each map entry declares
an immutable image digest, CPU/memory, desired/min/max count, optional private
ingress sources, task configuration, secret ARNs, narrow task policies, and
optional Cognito client settings. Empty maps are valid and create nothing.

Before a service entry is approved, the application owner must provide:

- ECR image digest, SBOM/scan result, container port, health check, CPU/memory,
  desired/min/max capacity, and rollback image digest;
- non-secret configuration, secret ARNs/KMS keys, and the minimum AWS actions
  for the task role;
- confirmation that private endpoint-only egress supports every dependency;
- for OAuth, Cognito pool ID, HTTPS callback/logout URLs, scopes, and product
  ownership of email/SMS/domain decisions; and
- for public traffic, a separate approved ALB/API, Route 53, ACM, WAF, DNS,
  health-check, and incident/rollback design.

## Security and observability

Tasks receive no public IP. Their security groups permit no ingress by default
and allow TLS only to the VPC CIDR for private endpoints. Images use immutable
digests, ECR scan-on-push, KMS-encrypted logs, dedicated task/execution roles,
and deployment circuit-breaker rollback. GitHub never holds long-lived AWS
keys; plan, apply, and drift use short-lived OIDC sessions.

Operational evidence is CloudTrail, Terraform plan/apply logs, VPC Flow Logs,
CloudWatch application logs, ECS service events, deployment events, and
non-remediating drift results. A successful workflow is not service health:
the application owner must run the agreed synthetic/authentication check.

## Incident and recovery model

Application rollback is a reviewed `applications` map change to a prior image
digest or capacity setting through the protected workload workflow. The ECS
deployment circuit breaker rolls back failed deployments. Terraform state
recovery follows the state-restore runbook with a versioned backup, lock check,
refresh-only proof, and incident record. No incident process permits console
changes that diverge from Terraform.

## Current boundaries and next gates

The sandbox is not production or multi-Region. It has no account vending,
Transit Gateway, VPN/BGP, external ingress, Route 53/ACM/WAF, customer-managed
application secret, multi-Region Cognito replica, or public failover. Each
requires approved inputs and its own reviewed plan. The reusable workflow
library is published separately at
`hatan4ik/terraform-pipelines`; consumers pin its release commit and retain
their own protected environments and least-privilege OIDC roles.
