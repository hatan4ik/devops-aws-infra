#!/usr/bin/env bash
# Read-only guard for the ADR 0015 legacy state-backend adoption. It never
# lists state-object keys, reads state contents, or makes an AWS write call.
set -euo pipefail

bucket_name="platform-tf-state-shared-f3ddb8cc"
table_name="platform-tf-lock-table"
key_alias="alias/terraform-state-backend"
expected_account_id=""
region=""

usage() {
  cat <<'USAGE'
Usage: verify-legacy-state-backend-adoption.sh --account-id ACCOUNT_ID --region REGION

Uses AWS_PROFILE if it is set. The caller must already have short-lived AWS
credentials. This command performs read-only verification only.
USAGE
}

fail() {
  printf 'legacy state adoption preflight failed: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --account-id)
      expected_account_id="${2:-}"
      shift 2
      ;;
    --region)
      region="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown argument: $1"
      ;;
  esac
done

[[ "$expected_account_id" =~ ^[0-9]{12}$ ]] || fail "--account-id must be a 12-digit AWS account ID"
[[ "$region" =~ ^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$ ]] || fail "--region must be an AWS Region identifier"
command -v aws >/dev/null 2>&1 || fail "aws CLI is required"

aws_args=(--region "$region")
if [[ -n "${AWS_PROFILE:-}" ]]; then
  aws_args+=(--profile "$AWS_PROFILE")
fi

aws_read() {
  aws "${aws_args[@]}" "$@"
}

caller_account_id="$(aws_read sts get-caller-identity --query Account --output text)"
[[ "$caller_account_id" == "$expected_account_id" ]] || fail "caller account does not match --account-id"

versioning="$(aws_read s3api get-bucket-versioning --bucket "$bucket_name" --query Status --output text)"
[[ "$versioning" == "Enabled" ]] || fail "S3 versioning is not enabled"

encryption="$(aws_read s3api get-bucket-encryption --bucket "$bucket_name" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text)"
[[ "$encryption" == "aws:kms" ]] || fail "S3 default encryption is not SSE-KMS"

ownership="$(aws_read s3api get-bucket-ownership-controls --bucket "$bucket_name" --query 'OwnershipControls.Rules[0].ObjectOwnership' --output text)"
[[ "$ownership" == "BucketOwnerEnforced" ]] || fail "S3 Object Ownership is not BucketOwnerEnforced"

public_access="$(aws_read s3api get-public-access-block --bucket "$bucket_name" --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,BlockPublicPolicy,IgnorePublicAcls,RestrictPublicBuckets]' --output text)"
[[ "$public_access" == $'True\tTrue\tTrue\tTrue' ]] || fail "S3 public-access block is incomplete"

object_lock="$(aws_read s3api get-object-lock-configuration --bucket "$bucket_name" --query 'ObjectLockConfiguration.Rule.DefaultRetention.[Mode,Days]' --output text)"
[[ "$object_lock" == $'COMPLIANCE\t14' ]] || fail "S3 Object Lock is not COMPLIANCE for 14 days"

key_id="$(aws_read kms describe-key --key-id "$key_alias" --query 'KeyMetadata.KeyId' --output text)"
rotation="$(aws_read kms get-key-rotation-status --key-id "$key_id" --query KeyRotationEnabled --output text)"
[[ "$rotation" == "True" ]] || fail "KMS rotation is not enabled"

table_status="$(aws_read dynamodb describe-table --table-name "$table_name" --query Table.TableStatus --output text)"
[[ "$table_status" == "ACTIVE" ]] || fail "DynamoDB lock table is not ACTIVE"

billing_mode="$(aws_read dynamodb describe-table --table-name "$table_name" --query Table.BillingModeSummary.BillingMode --output text)"
[[ "$billing_mode" == "PAY_PER_REQUEST" ]] || fail "DynamoDB lock table is not on-demand"

pitr="$(aws_read dynamodb describe-continuous-backups --table-name "$table_name" --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' --output text)"
[[ "$pitr" == "ENABLED" ]] || fail "DynamoDB PITR is not enabled"

table_sse="$(aws_read dynamodb describe-table --table-name "$table_name" --query Table.SSEDescription.Status --output text)"
[[ "$table_sse" == "ENABLED" ]] || fail "DynamoDB SSE is not enabled"

printf 'PASS: legacy state-backend adoption preflight (account verified; no state content read)\n'
