# Sandbox workload GitOps delivery

## Purpose

Deliver private Fargate services through
`infra/active/roots/sandbox-workload/us-east-2/dev`. This runbook is valid only
for a reviewed application map and the protected GitHub OIDC delivery path.
It does not authorize local Terraform, public ingress, or a placeholder image.

## Preconditions

1. The sandbox delivery IAM root has applied the workload plan/apply policies
   and the GitHub variables `AWS_SANDBOX_WORKLOAD_{PLAN,APPLY,DRIFT}_ROLE_ARN`
   point to the approved scoped OIDC roles.
2. The sandbox network and platform roots have a no-change reconciliation plan.
   The platform must include the private `cognito-idp` endpoint before a
   no-NAT task calls Cognito.
3. The change supplies a digest-pinned ECR image, task sizing, health contract,
   private dependencies, secret ARNs, narrow task policy, and rollback digest.
4. OAuth changes additionally supply a Cognito pool ID, HTTPS callback/logout
   URLs, and approved scopes. Public ingress needs a separate ADR/root/plan.

## Delivery

1. Update only the approved `applications` entry in `terraform.tfvars` and,
   where necessary, the module release SHA in `main.tf`.
2. Open a pull request. Review the workload plan and quality checks. Stop for
   unexpected resource replacement, IAM expansion, public addressing, or a
   state/account/Region mismatch.
3. Merge to `main`, dispatch **Sandbox workload apply**, select the protected
   `dev` environment, and type `apply` exactly.
4. Verify ECS deployment state, task count, CloudWatch logs, service events,
   task security group, ECR digest, and the application-specific health/auth
   check. Then run the workload plan or drift workflow and retain no-change
   evidence.

## Rollback

Revert only the affected application's immutable image digest or typed runtime
setting in a new pull request. Do not delete an ECS service, alter its task
definition in the console, or edit Terraform state. If state recovery is
needed, stop and follow the [state-restore runbook](state-restore.md).
