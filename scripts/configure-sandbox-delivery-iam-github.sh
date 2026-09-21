#!/usr/bin/env bash
# Stores non-secret role ARNs only after the Terraform IAM adoption has added
# the root-specific policy attachments. It never writes AWS credentials.
set -euo pipefail

profile="AWS-hatan4ik-sandbox"
role_prefix="devops-aws-infra-sandbox"
repository="hatan4ik/devops-aws-infra"

usage() {
  cat <<'USAGE'
Usage: scripts/configure-sandbox-delivery-iam-github.sh [options]

Stores only role ARNs as GitHub variables:
  repository variable AWS_SANDBOX_DELIVERY_IAM_PLAN_ROLE_ARN
  dev environment variables AWS_SANDBOX_DELIVERY_IAM_APPLY_ROLE_ARN and
  AWS_SANDBOX_DELIVERY_IAM_DRIFT_ROLE_ARN

Options:
  --profile NAME       IAM Identity Center profile (default: AWS-hatan4ik-sandbox)
  --role-prefix PREFIX Existing OIDC role prefix (default: devops-aws-infra-sandbox)
  --repository OWNER/REPO GitHub repository (default: hatan4ik/devops-aws-infra)
  -h, --help           Show this message
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) profile="$2"; shift 2 ;;
    --role-prefix) role_prefix="$2"; shift 2 ;;
    --repository) repository="$2"; shift 2 ;;
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

role_arn() {
  aws iam get-role --profile "$profile" --role-name "$1" --query 'Role.Arn' --output text
}

plan_role_arn="$(role_arn "${role_prefix}-plan")"
apply_role_arn="$(role_arn "${role_prefix}-dev-apply")"
drift_role_arn="$(role_arn "${role_prefix}-drift")"

gh variable set AWS_SANDBOX_DELIVERY_IAM_PLAN_ROLE_ARN --repo "$repository" --body "$plan_role_arn"
gh variable set AWS_SANDBOX_DELIVERY_IAM_APPLY_ROLE_ARN --repo "$repository" --env dev --body "$apply_role_arn"
gh variable set AWS_SANDBOX_DELIVERY_IAM_DRIFT_ROLE_ARN --repo "$repository" --env dev --body "$drift_role_arn"

printf 'Configured non-secret sandbox delivery IAM role ARN variables for %s.\n' "$repository"
