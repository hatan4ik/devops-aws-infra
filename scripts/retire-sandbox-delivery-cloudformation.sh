#!/usr/bin/env bash
# Retires the three superseded sandbox CloudFormation bootstrap stacks after
# Terraform has adopted their physical IAM resources and role attachments.
set -euo pipefail

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root_directory="$repository_root/terraform/roots/sandbox-delivery/us-east-2/global"
oidc_template="$repository_root/archive/cloudformation-sandbox-bootstrap/templates/github-oidc.template.yaml"
network_template="$repository_root/archive/cloudformation-sandbox-bootstrap/templates/sandbox-network-delivery-policy.template.yaml"
platform_template="$repository_root/archive/cloudformation-sandbox-bootstrap/templates/sandbox-platform-delivery-policy.template.yaml"

profile="AWS-hatan4ik-sandbox"
region="us-east-2"
confirmation=""

usage() {
  cat <<'USAGE'
Usage: scripts/retire-sandbox-delivery-cloudformation.sh [options]

First records Retain policies in the three historical CloudFormation stacks,
then deletes the stacks. The OIDC provider, six roles, four managed policies,
and their attachments are retained in AWS and remain Terraform-owned. This
script refuses to proceed until Terraform adoption state proves ownership.

Options:
  --profile NAME        IAM Identity Center profile (default: AWS-hatan4ik-sandbox)
  --region REGION       CloudFormation Region (default: us-east-2)
  --confirm TEXT        Required: retire-sandbox-delivery-cloudformation
  -h, --help            Show this message.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) profile="$2"; shift 2 ;;
    --region) region="$2"; shift 2 ;;
    --confirm) confirmation="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$confirmation" == "retire-sandbox-delivery-cloudformation" ]] || {
  printf '%s\n' 'Refusing retirement: pass --confirm retire-sandbox-delivery-cloudformation.' >&2
  exit 64
}

caller_account_id="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
[[ "$caller_account_id" == "448871779014" ]] || {
  printf 'Refusing retirement: profile resolves to account %s, expected sandbox account 448871779014.\n' "$caller_account_id" >&2
  exit 1
}

command -v terraform >/dev/null || { printf 'Terraform is required.\n' >&2; exit 69; }

(
  export AWS_PROFILE="$profile"
  terraform -chdir="$root_directory" init -input=false -lockfile=readonly -backend-config=backend.hcl >/dev/null
  state_addresses="$(terraform -chdir="$root_directory" state list)"

  for address in \
    'module.sandbox_delivery_iam.aws_iam_openid_connect_provider.github_actions' \
    'module.sandbox_delivery_iam.aws_iam_role.github_actions["plan"]' \
    'module.sandbox_delivery_iam.aws_iam_role.github_actions["dev_apply"]' \
    'module.sandbox_delivery_iam.aws_iam_role.github_actions["staging_apply"]' \
    'module.sandbox_delivery_iam.aws_iam_role.github_actions["prod_apply"]' \
    'module.sandbox_delivery_iam.aws_iam_role.github_actions["drift"]' \
    'module.sandbox_delivery_iam.aws_iam_role.github_actions["landing_zone"]' \
    'module.sandbox_delivery_iam.aws_iam_policy.sandbox_network_plan' \
    'module.sandbox_delivery_iam.aws_iam_policy.sandbox_network_dev_apply' \
    'module.sandbox_delivery_iam.aws_iam_policy.sandbox_platform_plan' \
    'module.sandbox_delivery_iam.aws_iam_policy.sandbox_platform_dev_apply' \
    'module.sandbox_delivery_iam.aws_iam_policy.identity_plan' \
    'module.sandbox_delivery_iam.aws_iam_policy.identity_dev_apply' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["network_plan_to_plan"]' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["network_plan_to_drift"]' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["network_apply_to_dev_apply"]' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["platform_plan_to_plan"]' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["platform_plan_to_drift"]' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["platform_apply_to_dev_apply"]' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["identity_plan_to_plan"]' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["identity_plan_to_drift"]' \
    'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["identity_apply_to_dev_apply"]'; do
    grep -Fqx "$address" <<<"$state_addresses"
  done
)

[[ -f "$oidc_template" && -f "$network_template" && -f "$platform_template" ]] || {
  printf '%s\n' 'The transitional Retain templates are missing; do not attempt a manual CloudFormation deletion.' >&2
  exit 1
}

state_kms_key_id="34605b23-fafd-43f8-b708-db4dbe385189"
common_parameters=(
  "RoleNamePrefix=devops-aws-infra-sandbox"
  "StateBucketName=platform-tf-state-shared-f3ddb8cc"
  "StateKmsKeyArn=arn:aws:kms:${region}:${caller_account_id}:key/${state_kms_key_id}"
  "StateLockTableArn=arn:aws:dynamodb:${region}:${caller_account_id}:table/platform-tf-lock-table"
)

aws cloudformation deploy \
  --profile "$profile" \
  --region "$region" \
  --stack-name devops-aws-infra-github-oidc \
  --template-file "$oidc_template" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset \
  --parameter-overrides \
    "GitHubSubjectPrefix=repo:hatan4ik@12816536/devops-aws-infra@1375932356" \
    "RoleNamePrefix=devops-aws-infra-sandbox" \
  --tags ManagedBy=devops-aws-infra Purpose=github-actions-oidc IaCOwnership=terraform

aws cloudformation deploy \
  --profile "$profile" \
  --region "$region" \
  --stack-name devops-aws-infra-sandbox-network-delivery-policy \
  --template-file "$network_template" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset \
  --parameter-overrides "${common_parameters[@]}" "StateKeyPrefix=gitops/sandbox-network/us-east-2/dev/" \
  --tags ManagedBy=devops-aws-infra Purpose=sandbox-network-gitops IaCOwnership=terraform

aws cloudformation deploy \
  --profile "$profile" \
  --region "$region" \
  --stack-name devops-aws-infra-sandbox-platform-delivery-policy \
  --template-file "$platform_template" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset \
  --parameter-overrides "${common_parameters[@]}" "StateKeyPrefix=gitops/sandbox-platform/us-east-2/dev/" \
  --tags ManagedBy=devops-aws-infra Purpose=sandbox-platform-gitops IaCOwnership=terraform

for stack_name in devops-aws-infra-github-oidc devops-aws-infra-sandbox-network-delivery-policy devops-aws-infra-sandbox-platform-delivery-policy; do
  stack_template_body="$(aws cloudformation get-template \
    --profile "$profile" \
    --region "$region" \
    --stack-name "$stack_name" \
    --template-stage Original \
    --query TemplateBody \
    --output text)"
  grep -Eq 'DeletionPolicy[[:space:]]*(:|":)[[:space:]]*"?Retain' <<<"$stack_template_body"
  aws cloudformation delete-stack --profile "$profile" --region "$region" --stack-name "$stack_name"
  aws cloudformation wait stack-delete-complete --profile "$profile" --region "$region" --stack-name "$stack_name"
done

for policy_arn in \
  "arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-network-plan" \
  "arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-network-dev-apply" \
  "arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-platform-plan" \
  "arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-platform-dev-apply"; do
  aws iam get-policy --profile "$profile" --policy-arn "$policy_arn" >/dev/null
done

aws iam get-open-id-connect-provider \
  --profile "$profile" \
  --open-id-connect-provider-arn "arn:aws:iam::${caller_account_id}:oidc-provider/token.actions.githubusercontent.com" >/dev/null

for role_name in \
  devops-aws-infra-sandbox-plan \
  devops-aws-infra-sandbox-dev-apply \
  devops-aws-infra-sandbox-staging-apply \
  devops-aws-infra-sandbox-prod-apply \
  devops-aws-infra-sandbox-drift \
  devops-aws-infra-sandbox-landing-zone; do
  aws iam get-role --profile "$profile" --role-name "$role_name" >/dev/null
done

assert_attached() {
  local role_name="$1"
  local policy_arn="$2"
  local attached_policy_arns

  attached_policy_arns="$(aws iam list-attached-role-policies \
    --profile "$profile" \
    --role-name "$role_name" \
    --query 'AttachedPolicies[].PolicyArn' \
    --output text)"
  tr '\t' '\n' <<<"$attached_policy_arns" | grep -Fqx "$policy_arn"
}

network_plan_arn="arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-network-plan"
network_apply_arn="arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-network-dev-apply"
platform_plan_arn="arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-platform-plan"
platform_apply_arn="arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-platform-dev-apply"
identity_plan_arn="arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-delivery-identity-plan"
identity_apply_arn="arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-delivery-identity-dev-apply"

assert_attached devops-aws-infra-sandbox-plan "$network_plan_arn"
assert_attached devops-aws-infra-sandbox-drift "$network_plan_arn"
assert_attached devops-aws-infra-sandbox-dev-apply "$network_apply_arn"
assert_attached devops-aws-infra-sandbox-plan "$platform_plan_arn"
assert_attached devops-aws-infra-sandbox-drift "$platform_plan_arn"
assert_attached devops-aws-infra-sandbox-dev-apply "$platform_apply_arn"
assert_attached devops-aws-infra-sandbox-plan "$identity_plan_arn"
assert_attached devops-aws-infra-sandbox-drift "$identity_plan_arn"
assert_attached devops-aws-infra-sandbox-dev-apply "$identity_apply_arn"

printf '%s\n' 'CloudFormation ownership retired. The OIDC provider, six roles, four delivery policies, and attachments remain present and are Terraform-owned; run the protected GitHub OIDC plan as the final no-change proof.'
