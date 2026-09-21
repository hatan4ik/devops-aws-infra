#!/usr/bin/env bash
# Attaches the reviewed root-specific delivery policies. It never creates VPC
# resources itself; Terraform remains the sole owner of the sandbox network.
set -euo pipefail

printf '%s\n' 'This CloudFormation policy bootstrap is archived. Sandbox delivery IAM is Terraform-owned; do not run this script.' >&2
exit 78

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
template_file="$repository_root/bootstrap/sandbox-network-delivery-policy/template.yaml"

profile="AWS-hatan4ik-sandbox"
region="us-east-2"
role_prefix="devops-aws-infra-sandbox"
stack_name="devops-aws-infra-sandbox-network-delivery-policy"
state_bucket="platform-tf-state-shared-f3ddb8cc"
state_key_prefix="gitops/sandbox-network/us-east-2/dev/"
state_kms_key_arn="arn:aws:kms:us-east-2:448871779014:key/34605b23-fafd-43f8-b708-db4dbe385189"
state_lock_table_arn="arn:aws:dynamodb:us-east-2:448871779014:table/platform-tf-lock-table"
allow_existing_state_key=false

usage() {
  cat <<'USAGE'
Usage: scripts/bootstrap-sandbox-network-delivery-policy.sh [options]

Deploys only the reviewed CloudFormation IAM policy stack for the sandbox
network GitHub OIDC roles. It does not run Terraform or create VPC resources.

Options:
  --profile NAME       IAM Identity Center profile (default: AWS-hatan4ik-sandbox)
  --region REGION      AWS Region for the CloudFormation stack (default: us-east-2)
  --role-prefix PREFIX Existing OIDC role prefix (default: devops-aws-infra-sandbox)
  --stack-name NAME    CloudFormation stack name
  --allow-existing-state-key
                      Permit a policy-stack update after the initial GitOps
                      apply has created the dedicated state object.
  -h, --help           Show this message
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) profile="$2"; shift 2 ;;
    --region) region="$2"; shift 2 ;;
    --role-prefix) role_prefix="$2"; shift 2 ;;
    --stack-name) stack_name="$2"; shift 2 ;;
    --allow-existing-state-key) allow_existing_state_key=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -f "$template_file" ]] || { printf 'Missing template: %s\n' "$template_file" >&2; exit 1; }

caller_account_id="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
[[ "$caller_account_id" == "448871779014" ]] || {
  printf 'Refusing to deploy policy stack: profile resolves to account %s, expected sandbox account 448871779014.\n' "$caller_account_id" >&2
  exit 1
}

state_object_count="$(aws s3api list-objects-v2 \
  --profile "$profile" \
  --region "$region" \
  --bucket "$state_bucket" \
  --prefix "${state_key_prefix}terraform.tfstate" \
  --max-keys 1 \
  --query 'KeyCount' \
  --output text)"

if [[ "$allow_existing_state_key" != true && "$state_object_count" != "0" ]]; then
  printf 'Refusing to bootstrap: the dedicated sandbox-network state object already exists. Use --allow-existing-state-key only for a reviewed policy-stack update.\n' >&2
  exit 1
fi

aws cloudformation validate-template \
  --profile "$profile" \
  --region "$region" \
  --template-body "file://$template_file" \
  --output json >/dev/null

aws cloudformation deploy \
  --profile "$profile" \
  --region "$region" \
  --stack-name "$stack_name" \
  --template-file "$template_file" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    "RoleNamePrefix=$role_prefix" \
    "StateBucketName=$state_bucket" \
    "StateKeyPrefix=$state_key_prefix" \
    "StateKmsKeyArn=$state_kms_key_arn" \
    "StateLockTableArn=$state_lock_table_arn" \
  --tags ManagedBy=devops-aws-infra Purpose=sandbox-network-gitops

aws cloudformation describe-stacks \
  --profile "$profile" \
  --region "$region" \
  --stack-name "$stack_name" \
  --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' \
  --output table
