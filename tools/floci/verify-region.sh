#!/usr/bin/env bash
# Verify the local Floci core and its optional web console without mutating
# containers, emulator state, or AWS resources.
set -euo pipefail

if [[ -z "${FLOCI_CORE_CONTAINER:-}" ]]; then
  if docker inspect floci >/dev/null 2>&1; then
    core_container="floci"
  elif docker inspect floci-local >/dev/null 2>&1; then
    core_container="floci-local"
  else
    core_container="floci"
  fi
else
  core_container="$FLOCI_CORE_CONTAINER"
fi

if [[ -z "${FLOCI_UI_CONTAINER:-}" ]]; then
  if docker inspect floci-aws-ui >/dev/null 2>&1; then
    ui_container="floci-aws-ui"
  elif docker inspect floci-ui >/dev/null 2>&1; then
    ui_container="floci-ui"
  elif docker inspect floci-local-ui >/dev/null 2>&1; then
    ui_container="floci-local-ui"
  else
    ui_container="floci-aws-ui"
  fi
else
  ui_container="$FLOCI_UI_CONTAINER"
fi
expected_region="${FLOCI_EXPECTED_REGION:-us-east-2}"
core_endpoint="${FLOCI_CORE_ENDPOINT:-http://localhost:4566}"

get_env() {
  local container="$1"
  local variable="$2"

  docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$container" |
    awk -F= -v key="$variable" '
      $1 == key {
        sub(/^[^=]*=/, "")
        print
        exit
      }
    '
}

get_status() {
  docker inspect --format '{{.State.Status}}' "$1"
}

print_value() {
  local label="$1"
  local value="$2"
  printf '%-24s %s\n' "$label" "${value:-NOT SET}"
}

check_core() {
  local errors=0
  local status region availability_zone

  printf '\n========================================\n'
  printf ' Container: %s (Floci core)\n' "$core_container"
  printf '========================================\n'

  if ! docker inspect "$core_container" >/dev/null 2>&1; then
    echo 'FAIL: Container does not exist'
    return 1
  fi

  status="$(get_status "$core_container")"
  region="$(get_env "$core_container" FLOCI_DEFAULT_REGION)"
  availability_zone="$(get_env "$core_container" FLOCI_DEFAULT_AVAILABILITY_ZONE)"

  print_value 'Status:' "$status"
  print_value 'FLOCI_DEFAULT_REGION:' "$region"
  print_value 'FLOCI_DEFAULT_AVAILABILITY_ZONE:' "$availability_zone"
  print_value 'Host endpoint:' "$core_endpoint"

  if [[ "$status" != 'running' ]]; then
    echo 'FAIL: Core container is not running'
    errors=$((errors + 1))
  fi

  if [[ "$region" != "$expected_region" ]]; then
    printf 'FAIL: FLOCI_DEFAULT_REGION must be %s\n' "$expected_region"
    errors=$((errors + 1))
  fi

  if ! curl --fail --silent --show-error --max-time 5 "$core_endpoint/" >/dev/null; then
    printf 'FAIL: Core endpoint is not reachable at %s\n' "$core_endpoint"
    errors=$((errors + 1))
  fi

  if (( errors == 0 )); then
    echo 'RESULT: PASS'
    return 0
  fi

  printf 'RESULT: FAIL (%d issue(s))\n' "$errors"
  return 1
}

check_ui() {
  local errors=0
  local status region default_region endpoint

  printf '\n========================================\n'
  printf ' Container: %s (Floci web UI)\n' "$ui_container"
  printf '========================================\n'

  if ! docker inspect "$ui_container" >/dev/null 2>&1; then
    echo 'FAIL: Container does not exist'
    return 1
  fi

  status="$(get_status "$ui_container")"
  region="$(get_env "$ui_container" AWS_REGION)"
  default_region="$(get_env "$ui_container" AWS_DEFAULT_REGION)"
  endpoint="$(get_env "$ui_container" FLOCI_ENDPOINT)"

  print_value 'Status:' "$status"
  print_value 'AWS_REGION:' "$region"
  print_value 'AWS_DEFAULT_REGION:' "$default_region"
  print_value 'FLOCI_ENDPOINT:' "$endpoint"

  if [[ "$status" != 'running' ]]; then
    echo 'FAIL: UI container is not running'
    errors=$((errors + 1))
  fi

  if [[ "$region" != "$expected_region" ]]; then
    printf 'FAIL: AWS_REGION must be %s\n' "$expected_region"
    errors=$((errors + 1))
  fi

  if [[ "$default_region" != "$expected_region" ]]; then
    printf 'FAIL: AWS_DEFAULT_REGION must be %s\n' "$expected_region"
    errors=$((errors + 1))
  fi

  case "$endpoint" in
    http://*|https://*) ;;
    *)
      echo 'FAIL: FLOCI_ENDPOINT must be an http(s) URL'
      errors=$((errors + 1))
      ;;
  esac

  if (( errors == 0 )); then
    echo 'RESULT: PASS'
    return 0
  fi

  printf 'RESULT: FAIL (%d issue(s))\n' "$errors"
  return 1
}

printf 'Floci Docker Region Verification\n'
printf 'Expected region: %s\n' "$expected_region"

core_result=0
ui_result=0
check_core || core_result=1
check_ui || ui_result=1

printf '\n========================================\n'
printf ' FINAL SUMMARY\n'
printf '========================================\n'

if (( core_result == 0 && ui_result == 0 )); then
  printf 'PASS: Core and UI are configured for %s\n' "$expected_region"
  exit 0
fi

(( core_result != 0 )) && echo 'FAIL: Floci core'
(( ui_result != 0 )) && echo 'FAIL: Floci AWS UI'
exit 1
