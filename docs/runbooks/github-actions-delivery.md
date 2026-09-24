# GitHub Actions Terraform delivery

## Scope and authority

This is the operator map for the active GitHub Actions delivery control plane.
Only roots under [`infra/active/`](../../infra/README.md) may reach AWS. Read
[Project status](../PROJECT-STATUS.md) and the root's pull-request plan before
dispatching an apply.

All active delivery workflows use a pinned action revision, short-lived GitHub
OIDC credentials, a root-specific role, `-lockfile=readonly`, and a dedicated
remote-state key. No active workflow accepts static AWS credentials. The
root-specific workflow files are intentionally thin callers of the local,
reviewed `_terraform-root-{plan,apply,drift}.yml` reusable workflows. This keeps
the implementation consistent without sharing an AWS role, state key, or
environment between roots. The separate
[terraform-pipelines](https://github.com/hatan4ik/terraform-pipelines)
repository provides reusable quality, plan, apply, drift, and release workflows
for other repositories; consumers pin its release commit.

## Workflow map

| Workflow family | Trigger | AWS authority | Result |
|---|---|---|---|
| `terraform-quality.yml` | Pull request, `main` push, manual | None | Formats, validates, mock-tests, lints, scans IaC, checks Markdown links and action pins. |
| `terraform-pr.yml` | Pull request to `main` | None | Enforces workflow contracts, action pins, and the active-root delivery boundary. |
| `oidc-sandbox-proof.yml` | Manual | Permissionless proof role | Verifies GitHub-to-AWS trust only; it does not run Terraform. |
| `organization-{plan,apply,drift}.yml` | PR/manual; manual apply; weekday schedule/manual drift | Organization plan/apply/drift roles | Operates only `organization/global`; backend values are supplied as protected GitHub variables at runtime. |
| `sandbox-delivery-iam-{plan,apply,drift}.yml` | PR/manual; manual apply; weekday schedule/manual drift | Sandbox delivery IAM plan/apply/drift roles | Operates only the Terraform-owned OIDC provider, roles, and policies. |
| `sandbox-network-{plan,apply,drift}.yml` | PR/manual; manual apply; weekday schedule/manual drift | Sandbox network plan/apply/drift roles | Operates only the isolated sandbox network root. |
| `sandbox-platform-{plan,apply,drift}.yml` | PR/manual; manual apply; weekday schedule/manual drift | Sandbox platform plan/apply/drift roles | Operates only the private ECS/Cognito/data platform root. |
| `sandbox-workload-{plan,apply,drift}.yml` | PR/manual; manual apply; weekday schedule/manual drift | Sandbox workload plan/apply/drift roles | Operates only the private Fargate-service root and has its own remote-state key. |

Each drift workflow uses `terraform plan -detailed-exitcode` and intentionally
fails when it detects drift. It never changes AWS.

The reusable apply workflow always checks out the repository default branch,
re-plans that protected revision, and applies the freshly generated plan once.
It does **not** apply a pull-request artifact. The workload caller additionally
waits for declared ECS services to become stable after apply.

## Delivery procedure

1. Make the root or module-version change in a pull request. The matching
   root plan and the credential-free quality checks must pass.
2. Review the plan. A plan that creates, updates, replaces, or destroys an
   unexpected resource is a stop condition, not an apply instruction.
3. Merge the approved pull request. Apply workflows always check out protected
   `main`, then re-plan that exact revision.
4. In GitHub Actions, dispatch the matching `*-apply.yml` workflow from
   `main` and enter the literal confirmation `apply`. The protected deployment
   environment and its root-specific apply role remain required.
5. Inspect the apply log and run the matching manual plan or drift workflow.
   Record a no-change plan as the reconciliation evidence.

Never run a local Terraform apply against an active root. Human AWS access is
for approved IAM Identity Center inspection or the narrow documented bootstrap
procedures only.
