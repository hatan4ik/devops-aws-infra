#!/usr/bin/env bash
# Re-encrypts exactly the versioned sandbox-delivery Terraform state object
# with the approved customer-managed KMS key. It never reads or prints state.
set -euo pipefail

profile="AWS-hatan4ik-sandbox"
region="us-east-2"
confirmation=""

bucket_name="platform-tf-state-shared-f3ddb8cc"
state_key="gitops/sandbox-delivery/us-east-2/global/terraform.tfstate"
lock_table_name="platform-tf-lock-table"
kms_key_alias="alias/terraform-state-backend"

usage() {
  cat <<'USAGE'
Usage: scripts/reencrypt-sandbox-delivery-state.sh [options]

Creates a new version of only the sandbox-delivery Terraform state object using
the approved customer-managed KMS key. It refuses to run when this state object
has an active Terraform lock and never prints state content.

Options:
  --profile NAME        IAM Identity Center profile (default: AWS-hatan4ik-sandbox)
  --region REGION       State backend Region (default: us-east-2)
  --confirm TEXT        Required: reencrypt-sandbox-delivery-state
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

[[ "$confirmation" == "reencrypt-sandbox-delivery-state" ]] || {
  printf '%s\n' 'Refusing state re-encryption: pass --confirm reencrypt-sandbox-delivery-state.' >&2
  exit 64
}

caller_account_id="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
[[ "$caller_account_id" == "448871779014" ]] || {
  printf 'Refusing state re-encryption: profile resolves to account %s, expected sandbox account 448871779014.\n' "$caller_account_id" >&2
  exit 1
}

expected_kms_key_arn="$(aws kms describe-key \
  --profile "$profile" \
  --region "$region" \
  --key-id "$kms_key_alias" \
  --query 'KeyMetadata.Arn' \
  --output text)"

bucket_default_kms_key_arn="$(aws s3api get-bucket-encryption \
  --profile "$profile" \
  --bucket "$bucket_name" \
  --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID' \
  --output text)"
[[ "$bucket_default_kms_key_arn" == "$expected_kms_key_arn" ]] || {
  printf 'Refusing state re-encryption: bucket default KMS key is %s, expected %s.\n' "$bucket_default_kms_key_arn" "$expected_kms_key_arn" >&2
  exit 1
}

state_lock_id="${bucket_name}/${state_key}"
target_lock_info="$(aws dynamodb get-item \
  --profile "$profile" \
  --region "$region" \
  --table-name "$lock_table_name" \
  --key "{\"LockID\":{\"S\":\"${state_lock_id}\"}}" \
  --projection-expression '#info' \
  --expression-attribute-names '{"#info":"Info"}' \
  --consistent-read \
  --query 'Item.Info.S' \
  --output text)"
[[ -z "$target_lock_info" || "$target_lock_info" == "None" ]] || {
  printf 'Refusing state re-encryption: %s has an active Terraform lock.\n' "$state_key" >&2
  exit 1
}

state_version_id="$(aws s3api head-object \
  --profile "$profile" \
  --bucket "$bucket_name" \
  --key "$state_key" \
  --query VersionId \
  --output text)"
state_encryption="$(aws s3api head-object \
  --profile "$profile" \
  --bucket "$bucket_name" \
  --key "$state_key" \
  --query ServerSideEncryption \
  --output text)"
state_kms_key_arn="$(aws s3api head-object \
  --profile "$profile" \
  --bucket "$bucket_name" \
  --key "$state_key" \
  --query SSEKMSKeyId \
  --output text)"

if [[ "$state_encryption" == "aws:kms" && "$state_kms_key_arn" == "$expected_kms_key_arn" ]]; then
  printf '%s\n' 'Sandbox delivery state already uses the approved customer-managed KMS key; no copy was made.'
  exit 0
fi

[[ "$state_encryption" == "AES256" ]] || {
  printf 'Refusing state re-encryption: current encryption is %s with KMS key %s.\n' "$state_encryption" "$state_kms_key_arn" >&2
  exit 1
}

new_version_id="$(aws s3api copy-object \
  --profile "$profile" \
  --region "$region" \
  --bucket "$bucket_name" \
  --key "$state_key" \
  --copy-source "${bucket_name}/${state_key}" \
  --metadata-directive COPY \
  --server-side-encryption aws:kms \
  --ssekms-key-id "$kms_key_alias" \
  --bucket-key-enabled \
  --query VersionId \
  --output text)"

observed_encryption="$(aws s3api head-object \
  --profile "$profile" \
  --bucket "$bucket_name" \
  --key "$state_key" \
  --query ServerSideEncryption \
  --output text)"
observed_kms_key_arn="$(aws s3api head-object \
  --profile "$profile" \
  --bucket "$bucket_name" \
  --key "$state_key" \
  --query SSEKMSKeyId \
  --output text)"
[[ "$new_version_id" != "$state_version_id" && "$observed_encryption" == "aws:kms" && "$observed_kms_key_arn" == "$expected_kms_key_arn" ]] || {
  printf '%s\n' 'State re-encryption verification failed; inspect the preserved object versions before retrying.' >&2
  exit 1
}

printf 'Sandbox delivery state re-encrypted with the approved KMS key; previous version %s remains preserved.\n' "$state_version_id"
