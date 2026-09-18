#!/usr/bin/env bash
# shellcheck disable=SC2016 # AWS CLI JMESPath uses literal backtick values.
# Read-only post-deployment check for a single regional TGW/VPN/VPC tuple.
# It issues only AWS CLI Describe/Get calls and makes no configuration changes.
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
USAGE
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
    --region) region="${2:?missing value for --region}"; shift 2 ;;
    --profile) profile="${2:?missing value for --profile}"; shift 2 ;;
    --tgw-attachment-id) attachment_id="${2:?missing value for --tgw-attachment-id}"; shift 2 ;;
    --tgw-route-table-id) route_table_id="${2:?missing value for --tgw-route-table-id}"; shift 2 ;;
    --vpn-connection-id) vpn_connection_id="${2:?missing value for --vpn-connection-id}"; shift 2 ;;
    --vpc-id) vpc_id="${2:?missing value for --vpc-id}"; shift 2 ;;
    --endpoint-service) endpoint_services+=("${2:?missing value for --endpoint-service}"); shift 2 ;;
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

attachment_state="$(ec2 describe-transit-gateway-attachments --transit-gateway-attachment-ids "$attachment_id" --query 'TransitGatewayAttachments[0].State' --output text)"
assert_equal "TGW attachment is available" "$attachment_state" "available"

association_state="$(ec2 get-transit-gateway-route-table-associations --transit-gateway-route-table-id "$route_table_id" --filters "Name=transit-gateway-attachment-id,Values=$attachment_id" --query 'Associations[0].State' --output text)"
assert_equal "TGW attachment has an explicit route-table association" "$association_state" "associated"

propagation_state="$(ec2 get-transit-gateway-route-table-propagations --transit-gateway-route-table-id "$route_table_id" --filters "Name=transit-gateway-attachment-id,Values=$attachment_id" --query 'TransitGatewayRouteTablePropagations[0].State' --output text)"
assert_equal "TGW attachment has the approved propagation" "$propagation_state" "enabled"

tunnel_count="$(ec2 describe-vpn-connections --vpn-connection-ids "$vpn_connection_id" --query 'length(VpnConnections[0].VgwTelemetry)' --output text)"
assert_minimum "VPN exposes two tunnel telemetry records" "$tunnel_count" 2
unhealthy_tunnels="$(ec2 describe-vpn-connections --vpn-connection-ids "$vpn_connection_id" --query 'VpnConnections[0].VgwTelemetry[?Status!=`UP`].Status' --output text)"
[[ -z "$unhealthy_tunnels" || "$unhealthy_tunnels" == "None" ]] || { echo "FAIL: one or more VPN tunnels are not UP" >&2; exit 1; }
echo "PASS: all reported VPN tunnels are UP"

flow_log_count="$(ec2 describe-flow-logs --filter "Name=resource-id,Values=$vpc_id" --query 'length(FlowLogs)' --output text)"
assert_minimum "VPC has Flow Logs" "$flow_log_count" 1
inactive_flow_logs="$(ec2 describe-flow-logs --filter "Name=resource-id,Values=$vpc_id" --query 'FlowLogs[?FlowLogStatus!=`ACTIVE`].FlowLogId' --output text)"
[[ -z "$inactive_flow_logs" || "$inactive_flow_logs" == "None" ]] || { echo "FAIL: one or more VPC Flow Logs are not ACTIVE" >&2; exit 1; }
echo "PASS: all reported VPC Flow Logs are ACTIVE"

for endpoint_service in "${endpoint_services[@]}"; do
  endpoint_count="$(ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc_id" "Name=service-name,Values=$endpoint_service" --query 'length(VpcEndpoints)' --output text)"
  assert_minimum "VPC endpoint exists for $endpoint_service" "$endpoint_count" 1
  unavailable_endpoints="$(ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc_id" "Name=service-name,Values=$endpoint_service" --query 'VpcEndpoints[?State!=`available`].VpcEndpointId' --output text)"
  [[ -z "$unavailable_endpoints" || "$unavailable_endpoints" == "None" ]] || { echo "FAIL: endpoint for $endpoint_service is not available" >&2; exit 1; }
  echo "PASS: endpoint for $endpoint_service is available"
done

echo "PASS: read-only network, VPN/BGP telemetry, endpoint, and Flow Log checks completed"
