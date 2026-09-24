# Project status and delivery authority

**Refreshed: 2026-09-24.** This document describes the reviewed GitOps
capability and the latest retained delivery evidence. It is not a substitute
for a fresh AWS read-only check before an operational decision.

## What is deployed

| Delivery lane | Current scope |
|---|---|
| Organizations | Management-account OUs, two baseline SCPs, and account records through the isolated Organization root. No account has been vended or moved by this source. |
| Delivery identity | GitHub OIDC plan, apply, and drift roles/policies are Terraform-owned in the sandbox account. |
| Sandbox network | Private `10.64.0.0/16` VPC, two private subnets, Flow Logs, required VPC endpoints, encrypted state, and no public route. |
| Sandbox platform | Private ECS cluster and ECR repository, Cognito user pool, KMS key, DynamoDB session table, and endpoint-only service dependencies. |
| Sandbox workload | The private `auth-demo` Fargate service, encrypted logs, scoped roles, private task security group, Cognito OAuth client, and autoscaling. The most recent protected workload apply completed successfully on 2026-09-23: [run 35905994999](https://github.com/hatan4ik/devops-aws-infra/actions/runs/35905994999). |

## What is not deployed

There is no Control Tower landing zone, member-account baseline, Transit
Gateway, VPN/BGP, second Region, public endpoint, public load balancer, Route
53 customer domain, WAF, production environment, or automated regional
failover. Those are roadmap items, not partially supported code paths.

## Operating authority

Only the five roots under [`infra/active`](../infra/README.md) may change AWS.
Each has its own remote-state key, OIDC roles, plan workflow, protected apply
workflow, and non-remediating drift workflow. The supported lifecycle is:

1. Change one active root or pin a released module commit.
2. Review the root-specific GitHub plan and quality checks in a pull request.
3. Merge to protected `main` only after the plan is accepted.
4. Dispatch the matching apply workflow with `confirm=apply` and protected
   environment approval.
5. Prove expected service behavior, then record a no-change plan or drift run.

Do not use local `terraform apply`, console changes, static AWS keys, or state
edits to bypass this lifecycle.

## Current gate

The next infrastructure change is the deliberately gated migration from
`aws.modules.ecs-service` v0.1.4 to the v1 module contract. It needs a signed
v1 module release, root-level Terraform `moved` blocks, a reviewed plan with no
replacement of the service security group, IAM roles, log group, autoscaling
target, or Cognito client, and the normal workload workflow. See the
[roadmap](ROADMAP.md) for the full ordered expansion path.

## Stop conditions

Stop before apply if the caller account/Region is wrong, the remote-state lock
is active, a plan contains an unexpected destroy or replacement, IAM expands
beyond the reviewed requirement, a route becomes public, or required deployment
evidence is missing.
