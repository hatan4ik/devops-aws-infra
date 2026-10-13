#!/usr/bin/env bash
# Stores non-secret sandbox-platform role ARN variables after its reviewed IAM
# policy stack is active. It never writes AWS credentials to GitHub.
set -euo pipefail

profile="AWS-hatan4ik-sandbox"
role_prefix="devops-aws-infra-sandbox"
repository="hatan4ik/devops-aws-infra"

usage() {
  cat <<'USAGE'
Usage: scripts/configure-sandbox-platform-github.sh [options]

Stores only role ARNs as GitHub variables:
  repository variable AWS_SANDBOX_PLATFORM_PLAN_ROLE_ARN
  dev environment variables AWS_SANDBOX_PLATFORM_APPLY_ROLE_ARN and
  AWS_SANDBOX_PLATFORM_DRIFT_ROLE_ARN

Options:
  --profile NAME       IAM Identity Center profile (default: AWS-hatan4ik-sandbox)
  --role-prefix PREFIX Existing OIDC role prefix (default: devops-aws-infra-sandbox)
  --repository OWNER/REPO GitHub repository (default: hatan4ik/devops-aws-infra)
  -h, --help           Show this message
USAGE
}

# A trailing option (or one followed by another option) must hit the usage
# path with exit 2 rather than a bare "unbound variable" abort.
require_value() {
  if [[ -z "${2-}" || "${2-}" == -* ]]; then
    printf 'Option %s requires a value.\n' "$1" >&2
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) require_value "$1" "${2-}"; profile="$2"; shift 2 ;;
    --role-prefix) require_value "$1" "${2-}"; role_prefix="$2"; shift 2 ;;
    --repository) require_value "$1" "${2-}"; repository="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

caller_account_id="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
[[ "$caller_account_id" == "448871779014" ]] || {
  printf 'Refusing to configure GitHub: profile resolves to account %s, expected sandbox account 448871779014.\n' "$caller_account_id" >&2
  exit 1
}

command -v gh >/dev/null || { printf 'GitHub CLI (gh) is required.\n' >&2; exit 1; }
gh auth status -h github.com >/dev/null

# The variables below are written to the dev environment. Check it with a GET
# before the first write so a missing environment cannot leave a half-configured
# repository (the repository-scope variable written, the environment ones not).
require_environment() {
  local environment_name="$1" error_output
  if ! error_output="$(gh api "repos/${repository}/environments/${environment_name}" --silent 2>&1)"; then
    if [[ "$error_output" == *"HTTP 404"* ]]; then
      printf 'GitHub environment "%s" does not exist in %s; no variables were written.\n' "$environment_name" "$repository" >&2
      printf 'Create it first: scripts/reconcile-github-controls.sh %s, then re-run this script.\n' "$repository" >&2
    else
      printf 'Could not read GitHub environment "%s" in %s; no variables were written:\n%s\n' "$environment_name" "$repository" "$error_output" >&2
    fi
    exit 1
  fi
}

require_environment dev

role_arn() {
  aws iam get-role --profile "$profile" --role-name "$1" --query 'Role.Arn' --output text
}

plan_role_arn="$(role_arn "${role_prefix}-plan")"
apply_role_arn="$(role_arn "${role_prefix}-dev-apply")"
drift_role_arn="$(role_arn "${role_prefix}-drift")"

gh variable set AWS_SANDBOX_PLATFORM_PLAN_ROLE_ARN --repo "$repository" --body "$plan_role_arn"
gh variable set AWS_SANDBOX_PLATFORM_APPLY_ROLE_ARN --repo "$repository" --env dev --body "$apply_role_arn"
gh variable set AWS_SANDBOX_PLATFORM_DRIFT_ROLE_ARN --repo "$repository" --env dev --body "$drift_role_arn"

printf 'Configured non-secret sandbox-platform role ARN variables for %s.\n' "$repository"
