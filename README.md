# AWS platform GitOps

This is the single GitOps repository for the AWS platform that exists today.
It contains executable Terraform roots, the GitHub OIDC delivery workflows that
operate them, and the documentation an operator needs to make a controlled
change. It contains no AWS credentials, Terraform state, local modules, or
unapproved future infrastructure.

## Start here

Read [project status](docs/PROJECT-STATUS.md), then the
[ConOps](docs/operations/conops.md). They state what is deployed, what is not,
and the only supported change path.

## One delivery path

```text
pull request -> root-specific GitHub plan -> reviewed merge
             -> protected GitHub OIDC apply -> post-apply drift check
```

| Active root | Workflow family | Responsibility |
|---|---|---|
| `organization/global` | `organization-{plan,apply,drift}.yml` | Organizations OUs, SCPs, and account records. |
| `sandbox-delivery/us-east-2/global` | `sandbox-delivery-iam-{plan,apply,drift}.yml` | GitHub OIDC delivery identity and scoped policies. |
| `sandbox-network/us-east-2/dev` | `sandbox-network-{plan,apply,drift}.yml` | Isolated sandbox VPC and network telemetry. |
| `sandbox-platform/us-east-2/dev` | `sandbox-platform-{plan,apply,drift}.yml` | Private ECS platform services and data dependencies. |
| `sandbox-workload/us-east-2/dev` | `sandbox-workload-{plan,apply,drift}.yml` | Private Fargate application services. |

Every apply requires protected `main`, a matching reviewed plan, an explicit
`confirm=apply` input, the protected GitHub environment, and short-lived OIDC
credentials. Local Terraform applies are not supported.

## Repository map

| Path | Purpose |
|---|---|
| [`infra/active`](infra/README.md) | The five executable Terraform roots and their shared naming context. |
| [`.github/workflows`](.github/workflows) | Root-specific plan, apply, and drift workflows. |
| [`bootstrap`](bootstrap/README.md) | The one-time Organizations control-plane prerequisite. |
| [`docs`](docs/README.md) | Current status, decisions, ConOps, roadmap, and runbooks. |
| [`scripts`](scripts) | Guarded local helpers and repository quality checks. |
| [`tests`](tests/README.md) | Read-only post-deployment verification contracts. |

Reusable Terraform belongs to the independently versioned
[`aws.modules.*` repositories](docs/MODULE-REPOSITORIES.md). Active roots pin
an exact release commit; they never copy a module or follow a branch.

Historical prototypes, copied third-party repositories, review snapshots, and
unapproved candidate roots have intentionally been removed from `main`.
They remain recoverable from Git history and are not a second implementation or
delivery path.
