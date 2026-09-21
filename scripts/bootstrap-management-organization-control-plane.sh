#!/usr/bin/env bash
# Creates only the management-account state backend and the reviewed IAM
# policies for the direct AWS Organizations Terraform root. Terraform remains
# the owner of OUs, SCPs, and account-vending resources.
set -euo pipefail

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
template_file="$repository_root/bootstrap/management-organization-delivery-policy/template.yaml"

profile="AWS-hatan4ik-management"
region="us-east-2"
role_prefix="devops-aws-infra-management"
stack_name="devops-aws-infra-management-organization-control-plane"
state_key_prefix="gitops/organization/global/"
state_lock_table="devops-aws-infra-organization-lock"
state_key_alias="alias/devops-aws-infra-organization-state"
state_bucket=""

usage() {
  cat <<'USAGE'
Usage: scripts/bootstrap-management-organization-control-plane.sh [options]

Creates the CloudFormation-owned Terraform state backend and least-privilege
GitHub OIDC policies for the direct Organizations root. It does not create,
move, or close an AWS account; it does not create Control Tower or VPN.

Options:
  --profile NAME              IAM Identity Center profile (default: AWS-hatan4ik-management)
  --region REGION             CloudFormation and state-backend Region (default: us-east-2)
  --role-prefix PREFIX        Existing GitHub OIDC role prefix
  --stack-name NAME           CloudFormation stack name
  --state-bucket NAME         Globally unique state bucket name; defaults to a deterministic account-specific name
  --state-key-prefix PREFIX   Dedicated state key prefix
  --state-lock-table NAME     Dedicated DynamoDB lock table
  --state-key-alias ALIAS     Customer-managed KMS alias for state encryption
  -h, --help                  Show this help
USAGE
}

while (($# > 0)); do
  case "$1" in
    --profile) profile="${2:?missing profile value}"; shift 2 ;;
    --region) region="${2:?missing region value}"; shift 2 ;;
    --role-prefix) role_prefix="${2:?missing role-prefix value}"; shift 2 ;;
    --stack-name) stack_name="${2:?missing stack-name value}"; shift 2 ;;
    --state-bucket) state_bucket="${2:?missing state-bucket value}"; shift 2 ;;
    --state-key-prefix) state_key_prefix="${2:?missing state-key-prefix value}"; shift 2 ;;
    --state-lock-table) state_lock_table="${2:?missing state-lock-table value}"; shift 2 ;;
    --state-key-alias) state_key_alias="${2:?missing state-key-alias value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

[[ -f "$template_file" ]] || { printf 'Missing template: %s\n' "$template_file" >&2; exit 66; }

caller_account_id="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
[[ "$caller_account_id" == "915507704945" ]] || {
  printf 'Refusing management control-plane bootstrap: profile resolves to %s, expected management account 915507704945.\n' "$caller_account_id" >&2
  exit 1
}

if [[ -z "$state_bucket" ]]; then
  state_bucket="devops-aws-infra-organization-state-${caller_account_id}"
fi

for role_name in "${role_prefix}-plan" "${role_prefix}-drift" "${role_prefix}-landing-zone"; do
  aws iam get-role --profile "$profile" --role-name "$role_name" --query 'Role.Arn' --output text >/dev/null
done

aws cloudformation validate-template \
  --profile "$profile" \
  --region "$region" \
  --template-body "file://$template_file" >/dev/null

printf 'Bootstrapping direct Organizations control plane in management account %s, region %s.\n' "$caller_account_id" "$region"
aws cloudformation deploy \
  --profile "$profile" \
  --region "$region" \
  --stack-name "$stack_name" \
  --template-file "$template_file" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset \
  --parameter-overrides \
    "RoleNamePrefix=$role_prefix" \
    "StateBucketName=$state_bucket" \
    "StateKeyPrefix=$state_key_prefix" \
    "StateLockTableName=$state_lock_table" \
    "StateKeyAlias=$state_key_alias" \
  --tags ManagedBy=devops-aws-infra Root=organization

aws cloudformation describe-stacks \
  --profile "$profile" \
  --region "$region" \
  --stack-name "$stack_name" \
  --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' \
  --output table
