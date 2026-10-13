#!/usr/bin/env bash
# Stores non-secret Organization control-plane role/backend values in GitHub
# only after the reviewed CloudFormation bootstrap is active.
set -euo pipefail

profile="AWS-hatan4ik-management"
region="us-east-2"
role_prefix="devops-aws-infra-management"
stack_name="devops-aws-infra-management-organization-control-plane"
repository="hatan4ik/devops-aws-infra"

usage() {
  cat <<'USAGE'
Usage: scripts/configure-organization-github.sh [options]

Creates the landing-zone GitHub Environment only if it does not exist, then
stores only non-secret role ARNs and Terraform backend identifiers. An existing
landing-zone Environment keeps its protection rules untouched. The dev
Environment must already exist (scripts/reconcile-github-controls.sh creates
it). Configure required reviewers/branch restrictions for landing-zone in
GitHub before any apply.

Options:
  --profile NAME       IAM Identity Center profile (default: AWS-hatan4ik-management)
  --region REGION      CloudFormation stack Region (default: us-east-2)
  --role-prefix PREFIX Existing GitHub OIDC role prefix
  --stack-name NAME    Management control-plane bootstrap stack name
  --repository OWNER/REPO GitHub repository (default: hatan4ik/devops-aws-infra)
  -h, --help           Show this help
USAGE
}

# A trailing option (or one followed by another option) must hit the usage
# path with exit 2 rather than a bare parameter-expansion abort.
require_value() {
  if [[ -z "${2-}" || "${2-}" == -* ]]; then
    printf 'Option %s requires a value.\n' "$1" >&2
    usage >&2
    exit 2
  fi
}

while (($# > 0)); do
  case "$1" in
    --profile) require_value "$1" "${2-}"; profile="$2"; shift 2 ;;
    --region) require_value "$1" "${2-}"; region="$2"; shift 2 ;;
    --role-prefix) require_value "$1" "${2-}"; role_prefix="$2"; shift 2 ;;
    --stack-name) require_value "$1" "${2-}"; stack_name="$2"; shift 2 ;;
    --repository) require_value "$1" "${2-}"; repository="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

caller_account_id="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
[[ "$caller_account_id" == "915507704945" ]] || {
  printf 'Refusing GitHub configuration: profile resolves to %s, expected management account 915507704945.\n' "$caller_account_id" >&2
  exit 1
}

command -v gh >/dev/null || { printf 'GitHub CLI (gh) is required.\n' >&2; exit 69; }
gh auth status -h github.com >/dev/null

stack_output() {
  aws cloudformation describe-stacks \
    --profile "$profile" \
    --region "$region" \
    --stack-name "$stack_name" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue | [0]" \
    --output text
}

plan_role_arn="$(stack_output PlanRoleArn)"
landing_zone_role_arn="$(stack_output LandingZoneRoleArn)"
state_bucket="$(stack_output StateBucketName)"
state_kms_key_arn="$(stack_output StateKmsKeyArn)"
state_lock_table="$(stack_output StateLockTableName)"
drift_role_arn="$(aws iam get-role --profile "$profile" --role-name "${role_prefix}-drift" --query 'Role.Arn' --output text)"

# `--output text` prints the literal "None" (exit 0) for an absent output key.
# Reject empty/None before anything is written to GitHub.
require_output() {
  if [[ -z "$2" || "$2" == "None" ]]; then
    printf 'No usable value for %s (got "%s") from stack %s in %s; is the bootstrap stack deployed and --stack-name correct? Nothing was written to GitHub.\n' "$1" "$2" "$stack_name" "$region" >&2
    exit 1
  fi
}
require_output PlanRoleArn "$plan_role_arn"
require_output LandingZoneRoleArn "$landing_zone_role_arn"
require_output StateBucketName "$state_bucket"
require_output StateKmsKeyArn "$state_kms_key_arn"
require_output StateLockTableName "$state_lock_table"
require_output "drift role ${role_prefix}-drift" "$drift_role_arn"

# The plan/landing-zone ARNs are synthesized by the template from
# RoleNamePrefix, while the drift ARN is looked up in IAM. They must describe
# the same role family (same path and prefix) or an override was inconsistent.
if [[ "${plan_role_arn%-plan}" != "${drift_role_arn%-drift}" || "${landing_zone_role_arn%-landing-zone}" != "${drift_role_arn%-drift}" ]]; then
  printf 'Role ARNs disagree; refusing to write GitHub variables.\n  plan:         %s\n  landing-zone: %s\n  drift:        %s\nCheck --role-prefix and --stack-name and the role path.\n' "$plan_role_arn" "$landing_zone_role_arn" "$drift_role_arn" >&2
  exit 1
fi

# GET-only probe. Prints "present" or "absent"; any other API failure is fatal
# so that nothing is written on top of an unreadable environment.
environment_state() {
  local error_output
  if error_output="$(gh api "repos/${repository}/environments/$1" --silent 2>&1)"; then
    printf 'present\n'
  elif [[ "$error_output" == *"HTTP 404"* ]]; then
    printf 'absent\n'
  else
    printf 'Could not read GitHub environment "%s" in %s; nothing was written:\n%s\n' "$1" "$repository" "$error_output" >&2
    return 1
  fi
}

# Every GET happens before the first write so a failure cannot leave the
# repository half-configured.
dev_state="$(environment_state dev)"
if [[ "$dev_state" != "present" ]]; then
  printf 'GitHub environment "dev" does not exist in %s; nothing was written.\n' "$repository" >&2
  printf 'Create it first: scripts/reconcile-github-controls.sh %s, then re-run this script.\n' "$repository" >&2
  exit 1
fi
landing_zone_state="$(environment_state landing-zone)"

# GitHub Environments are explicit OIDC trust boundaries. The create-or-update
# endpoint replaces protection rules with the supplied body, so an existing
# landing-zone Environment (reviewers, wait timer) is never PUT again. A new one
# is limited to protected branches; reviewer selection remains repository-owner
# policy and is therefore never inferred by this script.
if [[ "$landing_zone_state" == "absent" ]]; then
  gh api --method PUT "repos/${repository}/environments/landing-zone" \
    -F 'deployment_branch_policy[protected_branches]=true' \
    -F 'deployment_branch_policy[custom_branch_policies]=false' \
    --silent
  printf 'Created GitHub environment landing-zone (protected branches only). Add required reviewers before any apply.\n'
else
  printf 'GitHub environment landing-zone already exists; its protection rules were left untouched.\n'
fi

gh variable set AWS_ORGANIZATION_PLAN_ROLE_ARN --repo "$repository" --body "$plan_role_arn"
gh variable set AWS_ORGANIZATION_STATE_BUCKET --repo "$repository" --body "$state_bucket"
gh variable set AWS_ORGANIZATION_STATE_KMS_KEY_ARN --repo "$repository" --body "$state_kms_key_arn"
gh variable set AWS_ORGANIZATION_STATE_LOCK_TABLE --repo "$repository" --body "$state_lock_table"
gh variable set AWS_ORGANIZATION_LANDING_ZONE_ROLE_ARN --repo "$repository" --env landing-zone --body "$landing_zone_role_arn"
gh variable set AWS_ORGANIZATION_DRIFT_ROLE_ARN --repo "$repository" --env dev --body "$drift_role_arn"

printf 'Configured non-secret Organization GitHub variables for %s.\n' "$repository"
