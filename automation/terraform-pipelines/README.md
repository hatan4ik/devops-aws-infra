# Terraform pipeline templates — not active CI/CD

This directory is the reviewed reusable-workflow source for the initial
`hatan4ik/devops-aws-infra` GitOps repository under
[ADR 0017](../../docs/adr/0017-github-oidc-bootstrap-proof.md). It is not an
active GitHub Actions directory by itself because GitHub discovers workflows
only in a repository's top-level `.github/workflows/` directory. A future
pipeline-repository split requires a separate ADR and migration record.

No plan/apply/drift/release workflow from this staging area is active, no AWS identity is configured, and no release can be created from this staging area. The root credential-free Terraform quality workflow validates this source, but copying these reusable workflows to a newly approved pipeline repository and enabling callers remain separate remote-change gates.

## Workflow contracts

| Reusable workflow | Purpose | Required caller control |
|---|---|---|
| `terraform-quality.yml` | Formatting, validation, TFLint, mocked Terraform tests, Checkov, Trivy, and optionally generated-documentation drift. | A protected pull-request check; no AWS credentials. Call it once for each module/root directory rather than recursively linting a monorepo. |
| `terraform-plan.yml` | OIDC-authenticated, non-mutating Terraform plan plus Infracost base/head cost diff. | A least-privilege **plan** role, protected backend secret, and trusted `pull_request` caller. Never use `pull_request_target`. |
| `terraform-apply.yml` | Re-plan and apply only after the selected GitHub deployment environment grants approval. | Environment protection, a least-privilege **apply** role, a reviewed plan, and serialized state access. |
| `terraform-drift.yml` | Scheduled/manual read-only drift detection. It deliberately fails when drift is found and never remediates. | A read-only drift role and an external alert integration. |
| `module-release.yml` | Verify an immutable, annotated, GitHub-verified semantic-version tag; test and publish its GitHub release. | Protected signed tags and a protected `module-release` deployment environment. |

The caller supplies a base64-encoded backend configuration through the `backend_config_b64` secret. Its contents are written only to the ephemeral runner directory; the workflows do not print, upload, cache, or commit plans or backend configuration. Pass normal non-secret configuration through reviewed `*.tfvars` files and sensitive variables through environment-scoped GitHub secrets as `TF_VAR_<name>`.

## Consumer pattern after remote approval

The consumer must pin a reusable workflow to a full commit SHA of the approved pipeline repository. The following is intentionally a template, not a runnable reference until `<org>` and the pipeline commit are known:

```yaml
jobs:
  quality:
    uses: <org>/terraform-pipelines/.github/workflows/terraform-quality.yml@<FULL_40_CHAR_COMMIT_SHA>
    with:
      working_directory: .
      check_docs: true
```

For an AWS plan caller, use only the ordinary `pull_request` event, pass the base commit SHA and pull-request number, map an environment-scoped backend secret, and provide a dedicated plan-role ARN. The apply caller must use GitHub environment protection and a distinct apply-role ARN. Complete caller templates are in [`templates/`](templates/).

## Required remote setup before activation

1. Confirm the GitHub organization, team slugs, deployment-environment reviewers, repository visibility, and ruleset capabilities.
2. Create the pipeline repository and its protected default branch; require the quality workflow, CODEOWNERS, signed commits/tags, and SHA-pinned third-party actions.
3. Create separate AWS IAM OIDC roles for `plan`, `apply`, and `drift`. Their trust policies must constrain the immutable repository plus branch/environment subject available in `sub` and the audience `sts.amazonaws.com`. AWS cannot enforce a GitHub workflow-file claim; protect workflow provenance with the repository ruleset, CODEOWNERS, protected environments, and SHA-pinned actions. Their permissions must be resource-scoped and separate from break-glass roles.
4. Configure protected GitHub environments (`dev`, `staging`, `prod`, and `module-release`) with the required reviewers. Store the encrypted backend configuration and any `TF_VAR_*` secrets only at the minimum environment scope.
5. Dry-run the quality workflow first, then a sandbox plan with no apply permission. Record the OIDC subject, CloudTrail events, state-lock behavior, lint/security results, and cost-diff behavior before allowing an apply workflow.

Action provenance and the full immutable action pins used below are recorded in [`docs/architecture/action-pin-inventory.md`](../../docs/architecture/action-pin-inventory.md).

The future pipeline repository's `pipeline-self-test.yml` provides required `workflow_lint`, `action_pin_policy`, `reusable_workflow_test`, and `security_scan` check contexts. Its local guard scripts are under [`scripts/`](scripts/); no CI run has occurred in this staging workspace.
