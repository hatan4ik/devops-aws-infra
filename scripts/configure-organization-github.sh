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

Creates the landing-zone GitHub Environment if it does not exist, then stores
only non-secret role ARNs and Terraform backend identifiers. Configure required
reviewers/branch restrictions for that Environment in GitHub before any apply.

Options:
  --profile NAME       IAM Identity Center profile (default: AWS-hatan4ik-management)
  --region REGION      CloudFormation stack Region (default: us-east-2)
  --role-prefix PREFIX Existing GitHub OIDC role prefix
  --stack-name NAME    Management control-plane bootstrap stack name
  --repository OWNER/REPO GitHub repository (default: hatan4ik/devops-aws-infra)
  -h, --help           Show this help
USAGE
}

while (($# > 0)); do
  case "$1" in
    --profile) profile="${2:?missing profile value}"; shift 2 ;;
    --region) region="${2:?missing region value}"; shift 2 ;;
    --role-prefix) role_prefix="${2:?missing role-prefix value}"; shift 2 ;;
    --stack-name) stack_name="${2:?missing stack-name value}"; shift 2 ;;
    --repository) repository="${2:?missing repository value}"; shift 2 ;;
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

# GitHub Environments are explicit OIDC trust boundaries. Permit deployments
# only from a protected branch; reviewer selection remains repository-owner
# policy and is therefore never inferred by this script.
gh api --method PUT "repos/${repository}/environments/landing-zone" \
  -F 'deployment_branch_policy[protected_branches]=true' \
  -F 'deployment_branch_policy[custom_branch_policies]=false' \
  --silent

gh variable set AWS_ORGANIZATION_PLAN_ROLE_ARN --repo "$repository" --body "$plan_role_arn"
gh variable set AWS_ORGANIZATION_STATE_BUCKET --repo "$repository" --body "$state_bucket"
gh variable set AWS_ORGANIZATION_STATE_KMS_KEY_ARN --repo "$repository" --body "$state_kms_key_arn"
gh variable set AWS_ORGANIZATION_STATE_LOCK_TABLE --repo "$repository" --body "$state_lock_table"
gh variable set AWS_ORGANIZATION_LANDING_ZONE_ROLE_ARN --repo "$repository" --env landing-zone --body "$landing_zone_role_arn"
gh variable set AWS_ORGANIZATION_DRIFT_ROLE_ARN --repo "$repository" --env dev --body "$drift_role_arn"

printf 'Configured non-secret Organization GitHub variables for %s.\n' "$repository"
