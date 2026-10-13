#!/usr/bin/env bash
# Public, credential-free HTTPS smoke check. It sends no user data and does not
# authenticate or mutate application state. It issues HTTPS GET requests only
# (no HEAD, POST, or other methods).
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

Exit status: 0 all checks passed; 1 a check failed (wrong HTTP status or a
transport error such as DNS, connection, TLS, or timeout); 64 usage error;
69 curl is missing.
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

api_health_url=""
oidc_discovery_url=""
max_seconds="5"
while (($#)); do
  case "$1" in
    --api-health-url) need_value "$1" "${2-}"; api_health_url="$2"; shift 2 ;;
    --oidc-discovery-url) need_value "$1" "${2-}"; oidc_discovery_url="$2"; shift 2 ;;
    --max-seconds) need_value "$1" "${2-}"; max_seconds="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 64 ;;
  esac
done
[[ -n "$api_health_url" && -n "$oidc_discovery_url" ]] || { echo "--api-health-url and --oidc-discovery-url are required" >&2; usage >&2; exit 64; }
[[ "$api_health_url" =~ ^https:// && "$oidc_discovery_url" =~ ^https:// ]] || { echo "both URLs must use HTTPS" >&2; exit 64; }
[[ "$max_seconds" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "--max-seconds must be numeric" >&2; exit 64; }
# libcurl treats a 0 timeout as "never times out", which would remove the bound.
[[ "$max_seconds" =~ [1-9] ]] || { echo "--max-seconds must be greater than zero" >&2; exit 64; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 69; }

check_url() {
  local description="$1" url="$2" response status elapsed curl_status=0
  # Capture curl's status so a transport error (DNS, refused, TLS, timeout)
  # becomes an explicit FAIL line with exit 1, not curl's raw exit code.
  response="$(curl --connect-timeout "$max_seconds" --max-time "$max_seconds" --silent --show-error --output /dev/null --write-out '%{http_code} %{time_total}' "$url")" || curl_status=$?
  if ((curl_status != 0)); then
    echo "FAIL: $description request failed before an HTTP status was received (curl exit $curl_status)" >&2
    exit 1
  fi
  status="${response%% *}"
  elapsed="${response##* }"
  [[ "$status" == "200" ]] || { echo "FAIL: $description returned HTTP $status" >&2; exit 1; }
  echo "PASS: $description returned HTTP 200 in ${elapsed}s"
}

check_url "API health endpoint" "$api_health_url"
check_url "OIDC discovery endpoint" "$oidc_discovery_url"
echo "PASS: public credential-free synthetics completed"
