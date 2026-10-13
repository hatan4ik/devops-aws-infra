#!/usr/bin/env bash
# Read-only inspection for the GitOps-managed sandbox network. It never
# creates, changes, imports, or deletes AWS resources or Terraform state.
set -euo pipefail

profile="${AWS_PROFILE:-AWS-hatan4ik-sandbox}"
region="${AWS_REGION:-us-east-2}"
vpc_name="sandbox-network-dev"
expected_account_id="448871779014"
required_tags_json='["Application","CostCenter","Owner","Environment","ManagedBy","Repository","Root","Name"]'

usage() {
  cat <<'USAGE'
Usage: scripts/inspect-sandbox-network.sh [options]

Read-only inspection of the ADR 0018 sandbox network. This is an evidence
helper, not a provisioning path; GitHub OIDC Terraform remains the only writer.

Options:
  --profile NAME               IAM Identity Center profile (default: AWS_PROFILE or AWS-hatan4ik-sandbox)
  --region REGION              AWS Region (default: AWS_REGION or us-east-2)
  --vpc-name NAME              Expected VPC Name tag (default: sandbox-network-dev)
  --expected-account-id ID     Expected sandbox account (default: 448871779014)
  -h, --help                   Show this message
USAGE
}

# A trailing option (or one followed by another option) must hit the usage
# path with exit 2 rather than a bare "unbound variable" abort.
require_value() {
  if [[ -z "${2-}" || "${2-}" == -* ]]; then
    printf 'Option %s requires a value.\n' "$1" >&2
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) require_value "$1" "${2-}"; profile="$2"; shift 2 ;;
    --region) require_value "$1" "${2-}"; region="$2"; shift 2 ;;
    --vpc-name) require_value "$1" "${2-}"; vpc_name="$2"; shift 2 ;;
    --expected-account-id) require_value "$1" "${2-}"; expected_account_id="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v aws >/dev/null || { printf 'aws CLI is required.\n' >&2; exit 1; }
command -v jq >/dev/null || { printf 'jq is required.\n' >&2; exit 1; }

aws_cli() {
  command aws --profile "$profile" --region "$region" "$@"
}

caller_account_id="$(aws_cli sts get-caller-identity --query Account --output text)"
if [[ "$caller_account_id" != "$expected_account_id" ]]; then
  printf 'Refusing inspection: profile resolves to account %s, expected %s.\n' "$caller_account_id" "$expected_account_id" >&2
  exit 1
fi

vpcs_json="$(aws_cli ec2 describe-vpcs --filters "Name=tag:Name,Values=${vpc_name}" --output json)"
vpc_id="$(jq -r '.Vpcs[0].VpcId // empty' <<<"$vpcs_json")"
if [[ -z "$vpc_id" ]]; then
  printf 'No VPC tagged Name=%s exists in %s.\n' "$vpc_name" "$region" >&2
  exit 1
fi

# The evidence run must be complete: collect every failure and exit non-zero at
# the end instead of letting `set -e` abort on the first one.
failures=()
record_failure() {
  failures+=("$1")
}

# Informational sections: an AWS error is recorded, then the run continues.
run_section() {
  local label="$1"
  shift
  if ! "$@"; then
    record_failure "$label: AWS call failed"
  fi
}

check_tags() {
  local resource_type="$1"
  local resources_json="$2"
  local managed_resources_json

  managed_resources_json="$(jq '[.[] | select(any(.Tags[]?; .Key == "Root" and .Value == "sandbox-network"))]' <<<"$resources_json")"

  if [[ "$(jq 'length' <<<"$managed_resources_json")" == "0" ]]; then
    printf '  SKIP  %s (no Terraform-managed resources)\n' "$resource_type"
    return 0
  fi

  jq -r --arg resource_type "$resource_type" --argjson required "$required_tags_json" '
    .[] |
    (.Tags // [] | map(.Key)) as $actual |
    ($required - $actual) as $missing |
    if ($missing | length) == 0 then
      "  PASS  \($resource_type) \(.ResourceId)"
    else
      "  FAIL  \($resource_type) \(.ResourceId) - missing: \($missing | join(", "))"
    end
  ' <<<"$managed_resources_json"

  jq -e --argjson required "$required_tags_json" '
    all(.[]; ($required - ((.Tags // []) | map(.Key))) | length == 0)
  ' <<<"$managed_resources_json" >/dev/null
}

# Fetch the resources of one type and check their tags. Neither a failed fetch
# nor missing tags aborts the run; both are recorded.
check_resource_tags() {
  local resource_type="$1" resources_json
  shift
  if ! resources_json="$(aws_cli "$@")"; then
    printf '  FAIL  %s - could not list resources\n' "$resource_type"
    record_failure "$resource_type tag compliance: AWS call failed"
    return 0
  fi
  if ! check_tags "$resource_type" "$resources_json"; then
    record_failure "$resource_type tag compliance: required tags missing"
  fi
}

printf '=== Caller ===\n'
printf 'Account: %s\nRegion: %s\nProfile: %s\n' "$caller_account_id" "$region" "$profile"

printf '\n=== VPC ===\n'
# shellcheck disable=SC2016 # AWS CLI JMESPath expression, not shell syntax.
run_section "VPC" aws_cli ec2 describe-vpcs --vpc-ids "$vpc_id" \
  --query 'Vpcs[].{VpcId:VpcId,CIDR:CidrBlock,State:State,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

printf '\n=== VPC Encryption Control ===\n'
# describe-vpc-encryption-controls is a recent EC2 API. An aws-cli that predates
# it rejects the OPERATION NAME as an invalid argument; that is an expected,
# tolerated degradation (SKIPPED), whereas any other failure is a real check
# failure. The wording differs between CLI generations ("Invalid choice, valid
# choices are" in 2.x early releases, "Found invalid choice '<op>'" in current
# ones), so match the argument name plus either form, never a bare substring.
skipped_sections=0
if encryption_output="$(aws_cli ec2 describe-vpc-encryption-controls --vpc-id "$vpc_id" \
  --query 'VpcEncryptionControls[].{ControlId:VpcEncryptionControlId,Mode:Mode,State:State,Message:StateMessage}' \
  --output table 2>&1)"; then
  printf '%s\n' "$encryption_output"
elif grep -Eqi 'argument operation:.*invalid choice' <<<"$encryption_output"; then
  printf '  SKIPPED  installed aws-cli has no describe-vpc-encryption-controls; upgrade aws-cli to inspect VPC encryption control\n'
  skipped_sections=$((skipped_sections + 1))
else
  printf '%s\n' "$encryption_output" >&2
  record_failure "VPC encryption control: AWS call failed"
fi

printf '\n=== Private Subnets ===\n'
# shellcheck disable=SC2016 # AWS CLI JMESPath expression, not shell syntax.
run_section "Private Subnets" aws_cli ec2 describe-subnets --filters "Name=vpc-id,Values=${vpc_id}" \
  --query 'Subnets[].{SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock,MapPublicIp:MapPublicIpOnLaunch,Tier:Tags[?Key==`Tier`]|[0].Value}' \
  --output table

printf '\n=== Non-local Route Targets (must be empty for this isolated slice) ===\n'
# shellcheck disable=SC2016 # AWS CLI JMESPath expression, not shell syntax.
run_section "Non-local Route Targets" aws_cli ec2 describe-route-tables --filters "Name=vpc-id,Values=${vpc_id}" \
  --query 'RouteTables[].{RouteTableId:RouteTableId,Name:Tags[?Key==`Name`]|[0].Value,NonLocalRoutes:Routes[?GatewayId!=`local`]}' \
  --output json

printf '\n=== VPC Endpoints (none are authorized in this slice) ===\n'
run_section "VPC Endpoints" aws_cli ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=${vpc_id}" \
  --query 'VpcEndpoints[].{EndpointId:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType,State:State}' \
  --output table

printf '\n=== Security Groups ===\n'
run_section "Security Groups" aws_cli ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}" \
  --query 'SecurityGroups[].{GroupId:GroupId,Name:GroupName,Ingress:IpPermissions,Egress:IpPermissionsEgress}' \
  --output json

printf '\n=== VPC Flow Logs ===\n'
run_section "VPC Flow Logs" aws_cli ec2 describe-flow-logs --filter "Name=resource-id,Values=${vpc_id}" \
  --query 'FlowLogs[].{FlowLogId:FlowLogId,Status:FlowLogStatus,Destination:LogDestination,TrafficType:TrafficType}' \
  --output table

printf '\n=== Required Tag Compliance ===\n'
if ! check_tags "VPC" "$(jq '[.Vpcs[] | {ResourceId: .VpcId, Tags: .Tags}]' <<<"$vpcs_json")"; then
  record_failure "VPC tag compliance: required tags missing"
fi
check_resource_tags "Subnet" ec2 describe-subnets --filters "Name=vpc-id,Values=${vpc_id}" --query 'Subnets[].{ResourceId:SubnetId,Tags:Tags}' --output json
check_resource_tags "RouteTable" ec2 describe-route-tables --filters "Name=vpc-id,Values=${vpc_id}" --query 'RouteTables[].{ResourceId:RouteTableId,Tags:Tags}' --output json
check_resource_tags "SecurityGroup" ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}" --query 'SecurityGroups[].{ResourceId:GroupId,Tags:Tags}' --output json

if ((${#failures[@]} > 0)); then
  printf '\nFAIL: %d inspection check(s) failed:\n' "${#failures[@]}" >&2
  printf '  - %s\n' "${failures[@]}" >&2
  exit 1
fi

if ((skipped_sections > 0)); then
  printf '\nPASS (with %d section(s) SKIPPED, see above): inspection completed without mutating AWS or Terraform state.\n' "$skipped_sections"
else
  printf '\nPASS: inspection completed without mutating AWS or Terraform state.\n'
fi
