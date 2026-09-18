#!/usr/bin/env bash
# Public, credential-free HTTPS smoke check. It sends no user data and does not
# authenticate or mutate application state.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  verify_public_synthetics.sh --api-health-url URL --oidc-discovery-url URL [--max-seconds SECONDS]

Both endpoints must be approved production-like HTTPS endpoints. The API health
endpoint and the OIDC discovery document must each return HTTP 200 within the
configured maximum. This is an availability smoke test, not an authentication or
authorization test; see auth-api-synthetic-contract.md for the isolated-user
journey that must run in staging.
USAGE
}

api_health_url=""
oidc_discovery_url=""
max_seconds="5"
while (($#)); do
  case "$1" in
    --api-health-url) api_health_url="${2:?missing value for --api-health-url}"; shift 2 ;;
    --oidc-discovery-url) oidc_discovery_url="${2:?missing value for --oidc-discovery-url}"; shift 2 ;;
    --max-seconds) max_seconds="${2:?missing value for --max-seconds}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 64 ;;
  esac
done
[[ "$api_health_url" =~ ^https:// && "$oidc_discovery_url" =~ ^https:// ]] || { echo "both URLs must use HTTPS" >&2; exit 64; }
[[ "$max_seconds" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "--max-seconds must be numeric" >&2; exit 64; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 69; }

check_url() {
  local description="$1" url="$2" response status elapsed
  response="$(curl --connect-timeout "$max_seconds" --max-time "$max_seconds" --silent --show-error --output /dev/null --write-out '%{http_code} %{time_total}' "$url")"
  status="${response%% *}"
  elapsed="${response##* }"
  [[ "$status" == "200" ]] || { echo "FAIL: $description returned HTTP $status" >&2; exit 1; }
  echo "PASS: $description returned HTTP 200 in ${elapsed}s"
}

check_url "API health endpoint" "$api_health_url"
check_url "OIDC discovery endpoint" "$oidc_discovery_url"
echo "PASS: public credential-free synthetics completed"
