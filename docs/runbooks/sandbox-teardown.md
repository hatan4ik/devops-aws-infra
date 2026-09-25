# Sandbox application-plane teardown

## Purpose and boundary

This is the only supported way to remove the deployed sandbox application
plane before a clean rebuild. It is intentionally a **teardown**, not a
bootstrap reset. It destroys only these active Terraform roots, in dependency
order:

1. `sandbox-workload/us-east-2/dev` — private ECS services, task definitions,
   service roles, and the workload Cognito client.
2. `sandbox-platform/us-east-2/dev` — ECS cluster, platform security groups
   and endpoints, Cognito user pool, DynamoDB session table, ECR repository,
   CloudWatch log groups, and platform data key.
3. `sandbox-network/us-east-2/dev` — sandbox VPC, subnets, endpoints, flow
   logs, and network telemetry.

It deliberately retains the organization, Terraform state bucket and lock
table, KMS key for Terraform state, GitHub OIDC provider and delivery roles.
Those are the immutable control plane required to rebuild through GitOps. It
does not operate `organization/global` or
`sandbox-delivery/us-east-2/global`.

## Preconditions

- The teardown workflow change is merged to protected `main` and its required
  checks are green.
- The sandbox delivery IAM module release that grants
  `ecr:BatchDeleteImage` and the required KMS-key `kms:DeleteAlias`
  permission is pinned by
  `sandbox-delivery/us-east-2/global` and that delivery-IAM root has been
  applied. Until then the protected teardown stops before platform destruction
  if the ECR repository contains images or Terraform cannot remove the
  application-data alias.
- You have reviewed the current project status and have approval to erase the
  sandbox application plane. A teardown plan is evidence, not authorization
  to destroy a different revision.

The workflow uses GitHub OIDC and the existing protected `dev` environment.
Do not use local `terraform destroy`, AWS-console deletion, long-lived access
keys, or an ad-hoc AWS CLI cleanup.

## Data loss and recovery boundary

Destroying this plane permanently removes Cognito users and clients, DynamoDB
session data, ECR image digests, ECS service configuration, and platform log
groups. The workflow intentionally purges the ECR repository only after the
second exact acknowledgement below, because the module keeps ECR
`force_delete` disabled during normal operation.

The platform stage also deactivates deletion protection only for the Cognito
user pool and DynamoDB session table at the exact platform Terraform state
addresses. It reads the full current Cognito configuration and retains every
field accepted by `UpdateUserPool` before changing only deletion protection;
it then waits for both protections to be inactive. Do not run console or
ad-hoc CLI updates for these protections.

Before each root is destroyed, the workflow writes an encrypted Terraform
state snapshot under that root's state prefix:

```text
gitops/<root>/us-east-2/dev/backups/pre-destroy-<GitHub-run-id>.tfstate
```

The state bucket and its normal version history are retained. Treat those
snapshots as sensitive Terraform state; access them only through the
[state-restore procedure](state-restore.md). A platform KMS key may enter its
configured pending-deletion period rather than disappearing immediately.

## 1. Produce the mandatory destroy plan

In GitHub Actions, select **Sandbox application-plane teardown**, choose the
`main` branch, and set `operation` to `plan`. The workflow runs destruction
plans for workload, platform, and network with their narrow plan roles. It
does not change AWS.

Equivalent GitHub CLI command:

```bash
gh workflow run sandbox-teardown.yml \
  --repo hatan4ik/devops-aws-infra \
  --ref main \
  -f operation=plan
```

Wait for the run to succeed, inspect all three plans, and record its numeric
run ID. Every plan must show only the expected sandbox application-plane
deletions. Any unexpected deletion, replacement, permission error, or
non-empty control-plane scope is a stop condition.

After an interrupted teardown, an already-completed upstream root may
legitimately report zero deletes on the retry. That is a verified no-op; the
workflow continues in the documented dependency order.

## 2. Execute the protected teardown

Start a new workflow dispatch from `main`, with all four of these values:

```bash
gh workflow run sandbox-teardown.yml \
  --repo hatan4ik/devops-aws-infra \
  --ref main \
  -f operation=destroy \
  -f reviewed_plan_run_id=<successful-plan-run-id> \
  -f confirm=DESTROY-SANDBOX-APPLICATION-PLANE \
  -f acknowledge_data_loss=DELETE-COGNITO-ECR-DYNAMODB-LOGS
```

The workflow rejects the request unless the referenced plan succeeded from the
same protected `main` commit. It then re-plans each root immediately before
applying it once, takes the encrypted snapshot, and enforces this order:

```text
workload destroy -> platform destroy (including ECR purge) -> network destroy
```

The standard GitHub `dev` environment protection still applies. Never bypass
it by invoking Terraform locally.

## 3. Verify the clean application plane

After a successful run, trigger the normal manual plans for the three roots.
They must show only planned creations if the same source is still present; do
not apply them unless beginning an approved rebuild. Confirm separately that
the organization, delivery IAM, state bucket, lock table, and OIDC provider
remain present.

To rebuild, update the root pins to approved immutable module release commits,
review the normal root plans, then apply in the reverse dependency order:
network, platform, workload.
