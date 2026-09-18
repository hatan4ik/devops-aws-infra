#!/usr/bin/env bash
# shellcheck disable=SC2016 # AWS CLI JMESPath uses literal backtick values.
# Read-only security-account check. It fails closed when required services or
# current evidence are absent and makes no AWS configuration changes.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  verify_security_read_only.sh --region REGION --config-recorder-name NAME [--profile PROFILE]

Run from the approved Security/Audit delegated-administrator account. The script
requires Security Hub, GuardDuty, an organization multi-Region CloudTrail trail,
and the named AWS Config recorder to be enabled. It fails on every ACTIVE HIGH
or CRITICAL Security Hub finding; time-bound exceptions must be remediated or
archived through the documented security process before this strict gate passes.
USAGE
}

region=""
profile=""
config_recorder_name=""
while (($#)); do
  case "$1" in
    --region) region="${2:?missing value for --region}"; shift 2 ;;
    --profile) profile="${2:?missing value for --profile}"; shift 2 ;;
    --config-recorder-name) config_recorder_name="${2:?missing value for --config-recorder-name}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 64 ;;
  esac
done
[[ -n "$region" && -n "$config_recorder_name" ]] || { echo "--region and --config-recorder-name are required" >&2; usage >&2; exit 64; }
command -v aws >/dev/null 2>&1 || { echo "aws CLI is required" >&2; exit 69; }

aws_args=(aws --region "$region")
[[ -n "$profile" ]] && aws_args+=(--profile "$profile")
assert_equal() {
  local description="$1" actual="$2" expected="$3"
  [[ "$actual" == "$expected" ]] || { echo "FAIL: $description (expected $expected; got $actual)" >&2; exit 1; }
  echo "PASS: $description"
}
assert_minimum() {
  local description="$1" actual="$2" minimum="$3"
  [[ "$actual" =~ ^[0-9]+$ && "$actual" -ge "$minimum" ]] || { echo "FAIL: $description (expected >= $minimum; got $actual)" >&2; exit 1; }
  echo "PASS: $description"
}

active_high_critical="$("${aws_args[@]}" securityhub get-findings --filters '{"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}],"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"},{"Value":"CRITICAL","Comparison":"EQUALS"}]}' --query 'length(Findings)' --output text)"
assert_equal "Security Hub has no ACTIVE HIGH/CRITICAL findings" "$active_high_critical" "0"

detector_id="$("${aws_args[@]}" guardduty list-detectors --query 'DetectorIds[0]' --output text)"
[[ -n "$detector_id" && "$detector_id" != "None" ]] || { echo "FAIL: GuardDuty detector is absent" >&2; exit 1; }
guardduty_status="$("${aws_args[@]}" guardduty get-detector --detector-id "$detector_id" --query 'Status' --output text)"
assert_equal "GuardDuty detector is enabled" "$guardduty_status" "ENABLED"

organization_trail_count="$("${aws_args[@]}" cloudtrail describe-trails --include-shadow-trails --query 'length(trailList[?IsOrganizationTrail==`true` && IsMultiRegionTrail==`true`])' --output text)"
assert_minimum "organization multi-Region CloudTrail trail exists" "$organization_trail_count" 1

config_status="$("${aws_args[@]}" configservice describe-configuration-recorder-status --configuration-recorder-names "$config_recorder_name" --query 'ConfigurationRecordersStatus[0].recording' --output text)"
assert_equal "AWS Config recorder is recording" "$config_status" "True"

echo "PASS: read-only security baseline checks completed"
