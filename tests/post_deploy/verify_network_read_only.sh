#!/usr/bin/env bash
# shellcheck disable=SC2016 # AWS CLI JMESPath uses literal backtick values.
# Read-only post-deployment check for a single regional TGW/VPN/VPC tuple.
# It issues only AWS CLI Describe/Get calls and makes no configuration changes.
# Every assertion runs and every failure is reported; the exit status is
# non-zero at the end if any assertion failed (it does not stop at the first).
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  verify_network_read_only.sh --region REGION --tgw-attachment-id ID \
    --tgw-route-table-id ID --vpn-connection-id ID --vpc-id ID \
    --endpoint-service SERVICE [--endpoint-service SERVICE ...] [--profile PROFILE]

All identifiers must belong to the same approved account and Region. Require at
least one expected VPC endpoint service. This check fails if the specified TGW
attachment is unavailable, its association/propagation is absent, either VPN
tunnel is not UP, VPC Flow Logs are not ACTIVE, or an expected endpoint is not
available. It does not inspect route prefixes; validate the approved prefix
matrix separately during the network change review.

Exit status: 0 all assertions passed; 1 one or more assertions failed;
64 usage error; 69 the AWS CLI is missing.
USAGE
}

# A flag with no value must take the usage path (exit 64), not a bare
# parameter-expansion abort.
need_value() {
  if [[ -z "${2-}" || "${2-}" == -* ]]; then
    echo "missing value for $1" >&2
    usage >&2
    exit 64
  fi
}

region=""
profile=""
attachment_id=""
route_table_id=""
vpn_connection_id=""
vpc_id=""
declare -a endpoint_services=()

while (($#)); do
  case "$1" in
    --region) need_value "$1" "${2-}"; region="$2"; shift 2 ;;
    --profile) need_value "$1" "${2-}"; profile="$2"; shift 2 ;;
    --tgw-attachment-id) need_value "$1" "${2-}"; attachment_id="$2"; shift 2 ;;
    --tgw-route-table-id) need_value "$1" "${2-}"; route_table_id="$2"; shift 2 ;;
    --vpn-connection-id) need_value "$1" "${2-}"; vpn_connection_id="$2"; shift 2 ;;
    --vpc-id) need_value "$1" "${2-}"; vpc_id="$2"; shift 2 ;;
    --endpoint-service) need_value "$1" "${2-}"; endpoint_services+=("$2"); shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 64 ;;
  esac
done

for required in region attachment_id route_table_id vpn_connection_id vpc_id; do
  [[ -n "${!required}" ]] || { echo "missing required argument: $required" >&2; usage >&2; exit 64; }
done
(( ${#endpoint_services[@]} > 0 )) || { echo "at least one --endpoint-service is required" >&2; usage >&2; exit 64; }
command -v aws >/dev/null 2>&1 || { echo "aws CLI is required" >&2; exit 69; }

aws_args=(aws --region "$region")
[[ -n "$profile" ]] && aws_args+=(--profile "$profile")
ec2() { "${aws_args[@]}" ec2 "$@"; }

# Fail-soft: a failed assertion is counted and reported, and the run continues.
# last_assertion_passed lets a dependent check be skipped when its prerequisite
# assertion failed (so it cannot print a misleading PASS).
failed_assertions=0
last_assertion_passed=0
fail_assertion() {
  echo "FAIL: $1" >&2
  failed_assertions=$((failed_assertions + 1))
  last_assertion_passed=0
}
pass_assertion() {
  echo "PASS: $1"
  last_assertion_passed=1
}
assert_equal() {
  local description="$1" actual="$2" expected="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass_assertion "$description"
  else
    fail_assertion "$description (expected $expected; got $actual)"
  fi
}
assert_minimum() {
  local description="$1" actual="$2" minimum="$3"
  if [[ "$actual" =~ ^[0-9]+$ && "$actual" -ge "$minimum" ]]; then
    pass_assertion "$description"
  else
    fail_assertion "$description (expected >= $minimum; got $actual)"
  fi
}
# Passes when the query listed nothing (empty or the CLI's literal "None").
assert_none_listed() {
  local pass_message="$1" fail_message="$2" actual="$3"
  if [[ -z "$actual" || "$actual" == "None" ]]; then
    pass_assertion "$pass_message"
  elif [[ "$actual" == "$QUERY_FAILED" ]]; then
    fail_assertion "$fail_message (AWS query failed)"
  else
    fail_assertion "$fail_message"
  fi
}
# An AWS call that errors (unknown ID, no access) is itself a failed assertion;
# the CLI has already printed its own error on stderr.
QUERY_FAILED="<query failed>"

attachment_state="$(ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids "$attachment_id" --query 'TransitGatewayAttachments[0].State' --output text)" || attachment_state="$QUERY_FAILED"
assert_equal "TGW attachment is available" "$attachment_state" "available"

association_state="$(ec2 get-transit-gateway-route-table-associations --transit-gateway-route-table-id "$route_table_id" --filters "Name=transit-gateway-attachment-id,Values=$attachment_id" --query 'Associations[0].State' --output text)" || association_state="$QUERY_FAILED"
assert_equal "TGW attachment has an explicit route-table association" "$association_state" "associated"

propagation_state="$(ec2 get-transit-gateway-route-table-propagations --transit-gateway-route-table-id "$route_table_id" --filters "Name=transit-gateway-attachment-id,Values=$attachment_id" --query 'TransitGatewayRouteTablePropagations[0].State' --output text)" || propagation_state="$QUERY_FAILED"
assert_equal "TGW attachment has the approved propagation" "$propagation_state" "enabled"

# `|| `[]`` keeps an absent VPN connection a counted assertion failure (0
# records) instead of a JMESPath error from length(null).
tunnel_count="$(ec2 describe-vpn-connections --vpn-connection-ids "$vpn_connection_id" --query 'length(VpnConnections[0].VgwTelemetry || `[]`)' --output text)" || tunnel_count="$QUERY_FAILED"
assert_minimum "VPN exposes two tunnel telemetry records" "$tunnel_count" 2
if ((last_assertion_passed)); then
  unhealthy_tunnels="$(ec2 describe-vpn-connections --vpn-connection-ids "$vpn_connection_id" --query 'VpnConnections[0].VgwTelemetry[?Status!=`UP`].Status' --output text)" || unhealthy_tunnels="$QUERY_FAILED"
  assert_none_listed "all reported VPN tunnels are UP" "one or more VPN tunnels are not UP" "$unhealthy_tunnels"
else
  echo "SKIP: VPN tunnel status (telemetry record assertion failed)"
fi

flow_log_count="$(ec2 describe-flow-logs --filter "Name=resource-id,Values=$vpc_id" --query 'length(FlowLogs)' --output text)" || flow_log_count="$QUERY_FAILED"
assert_minimum "VPC has Flow Logs" "$flow_log_count" 1
if ((last_assertion_passed)); then
  inactive_flow_logs="$(ec2 describe-flow-logs --filter "Name=resource-id,Values=$vpc_id" --query 'FlowLogs[?FlowLogStatus!=`ACTIVE`].FlowLogId' --output text)" || inactive_flow_logs="$QUERY_FAILED"
  assert_none_listed "all reported VPC Flow Logs are ACTIVE" "one or more VPC Flow Logs are not ACTIVE" "$inactive_flow_logs"
else
  echo "SKIP: VPC Flow Log status (Flow Log existence assertion failed)"
fi

for endpoint_service in "${endpoint_services[@]}"; do
  endpoint_count="$(ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc_id" "Name=service-name,Values=$endpoint_service" --query 'length(VpcEndpoints)' --output text)" || endpoint_count="$QUERY_FAILED"
  assert_minimum "VPC endpoint exists for $endpoint_service" "$endpoint_count" 1
  if ((last_assertion_passed)); then
    unavailable_endpoints="$(ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc_id" "Name=service-name,Values=$endpoint_service" --query 'VpcEndpoints[?State!=`available`].VpcEndpointId' --output text)" || unavailable_endpoints="$QUERY_FAILED"
    assert_none_listed "endpoint for $endpoint_service is available" "endpoint for $endpoint_service is not available" "$unavailable_endpoints"
  else
    echo "SKIP: endpoint state for $endpoint_service (existence assertion failed)"
  fi
done

if ((failed_assertions > 0)); then
  echo "FAIL: $failed_assertions network assertion(s) failed; see the FAIL lines above" >&2
  exit 1
fi
echo "PASS: read-only network, VPN/BGP telemetry, endpoint, and Flow Log checks completed"
