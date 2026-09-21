#!/usr/bin/env bash
# Performs the single, documented IAM Identity Center Terraform adoption that
# transfers existing sandbox delivery policies from CloudFormation to Terraform.
set -euo pipefail

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root_directory="$repository_root/terraform/roots/sandbox-delivery/us-east-2/global"

profile="AWS-hatan4ik-sandbox"
apply=false
confirmation=""

usage() {
  cat <<'USAGE'
Usage: scripts/adopt-sandbox-delivery-iam.sh [options]

Creates an import plan for the existing sandbox GitHub OIDC provider, six OIDC
roles, four network/platform delivery policies, and their six existing role
attachments. With --apply and the exact confirmation, it records those imports
in dedicated Terraform state and creates only the two new, bounded IAM policies
required for later GitHub OIDC Terraform policy delivery. It never creates a
VPC, application, account, key, or AWS credential.

Options:
  --profile NAME        IAM Identity Center profile (default: AWS-hatan4ik-sandbox)
  --apply               Apply the reviewed import plan.
  --confirm TEXT        Required with --apply: adopt-sandbox-delivery-iam
  -h, --help            Show this message.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) profile="$2"; shift 2 ;;
    --apply) apply=true; shift ;;
    --confirm) confirmation="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$apply" == true && "$confirmation" != "adopt-sandbox-delivery-iam" ]]; then
  printf '%s\n' 'Refusing to apply: pass --confirm adopt-sandbox-delivery-iam.' >&2
  exit 64
fi

caller_account_id="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
[[ "$caller_account_id" == "448871779014" ]] || {
  printf 'Refusing adoption: profile resolves to account %s, expected sandbox account 448871779014.\n' "$caller_account_id" >&2
  exit 1
}

state_kms_key_id="34605b23-fafd-43f8-b708-db4dbe385189"
expected_state_kms_key_arn="arn:aws:kms:us-east-2:${caller_account_id}:key/${state_kms_key_id}"
observed_state_kms_key_arn="$(aws s3api get-bucket-encryption \
  --profile "$profile" \
  --bucket platform-tf-state-shared-f3ddb8cc \
  --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID' \
  --output text)"
[[ "$observed_state_kms_key_arn" == "$expected_state_kms_key_arn" ]] || {
  printf 'Refusing adoption: state bucket default KMS key is %s, expected %s.\n' "$observed_state_kms_key_arn" "$expected_state_kms_key_arn" >&2
  exit 1
}

required_policy_arns=(
  "arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-network-plan"
  "arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-network-dev-apply"
  "arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-platform-plan"
  "arn:aws:iam::${caller_account_id}:policy/devops-aws-infra-sandbox-sandbox-platform-dev-apply"
)

for policy_arn in "${required_policy_arns[@]}"; do
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

command -v terraform >/dev/null || { printf 'Terraform is required.\n' >&2; exit 69; }

plan_file="${TMPDIR:-/tmp}/sandbox-delivery-iam-adoption.tfplan"
trap 'rm -f -- "$plan_file"' EXIT

(
  export AWS_PROFILE="$profile"
  terraform -chdir="$root_directory" init -input=false -lockfile=readonly -backend-config=backend.hcl
  terraform -chdir="$root_directory" plan -input=false -lock-timeout=5m -var-file=terraform.tfvars -out="$plan_file"

  if [[ "$apply" == true ]]; then
    terraform -chdir="$root_directory" apply -input=false -lock-timeout=5m "$plan_file"

    for address in \
      'module.sandbox_delivery_iam.aws_iam_policy.sandbox_platform_dev_apply' \
      'module.sandbox_delivery_iam.aws_iam_policy.identity_plan' \
      'module.sandbox_delivery_iam.aws_iam_policy.identity_dev_apply' \
      'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["identity_plan_to_plan"]' \
      'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["identity_plan_to_drift"]' \
      'module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["identity_apply_to_dev_apply"]'; do
      terraform -chdir="$root_directory" state list | grep -Fqx "$address"
    done
  fi
)

if [[ "$apply" == true ]]; then
  printf '%s\n' 'Terraform adoption completed. Configure GitHub variables, run the protected OIDC plan, then retire the three archived CloudFormation stacks with scripts/retire-sandbox-delivery-cloudformation.sh.'
else
  printf '%s\n' 'Adoption plan completed without an AWS mutation. Re-run with --apply --confirm adopt-sandbox-delivery-iam only after review.'
fi
