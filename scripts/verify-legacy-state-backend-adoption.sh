#!/usr/bin/env bash
# Read-only guard for the ADR 0015 legacy state-backend adoption. It never
# lists state-object keys, reads state contents, or makes an AWS write call.
set -euo pipefail

expected_account_id=""
region=""
bucket_name=""
table_name=""
key_alias=""
object_lock_retention_mode=""
object_lock_retention_days=""

usage() {
  cat <<'USAGE'
Usage: verify-legacy-state-backend-adoption.sh \
  --account-id ACCOUNT_ID \
  --region REGION \
  --bucket-name BUCKET_NAME \
  --dynamodb-table-name TABLE_NAME \
  --kms-key-alias KMS_ALIAS \
  --object-lock-retention-mode MODE \
  --object-lock-retention-days DAYS

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
    --bucket-name)
      bucket_name="${2:-}"
      shift 2
      ;;
    --dynamodb-table-name)
      table_name="${2:-}"
      shift 2
      ;;
    --kms-key-alias)
      key_alias="${2:-}"
      shift 2
      ;;
    --object-lock-retention-mode)
      object_lock_retention_mode="${2:-}"
      shift 2
      ;;
    --object-lock-retention-days)
      object_lock_retention_days="${2:-}"
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
[[ "$bucket_name" =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]] || fail "--bucket-name must be a valid S3 bucket name"
[[ "$table_name" =~ ^[A-Za-z0-9_.-]{3,255}$ ]] || fail "--dynamodb-table-name must be a valid DynamoDB table name"
[[ "$key_alias" =~ ^alias/[A-Za-z0-9/_-]+$ ]] || fail "--kms-key-alias must begin with alias/"
[[ "$object_lock_retention_mode" == "COMPLIANCE" ]] || fail "--object-lock-retention-mode must be COMPLIANCE for this no-change adoption"
[[ "$object_lock_retention_days" =~ ^[1-9][0-9]*$ ]] || fail "--object-lock-retention-days must be a positive whole number"
command -v aws >/dev/null 2>&1 || fail "aws CLI is required"

aws_args=(--no-cli-pager --region "$region")
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
[[ "$object_lock" == "${object_lock_retention_mode}"$'\t'"${object_lock_retention_days}" ]] || fail "S3 Object Lock does not match the approved adoption inventory"

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
