# Archived pipeline-template bootstrap

This directory is historical evidence only. Its source was published as the
standalone [terraform-pipelines](https://github.com/hatan4ik/terraform-pipelines)
repository and released as `v0.1.0`. Consumers must use that repository and
pin its release commit; they must not copy workflows from this archive.

No workflow below is discovered, executed, or validated by the GitOps
repository. It contains no AWS identity and is retained only to preserve the
pre-release design and caller-template history.

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
