#!/usr/bin/env bash
# Report whether a dependent sandbox root has the live resources required for
# a meaningful Terraform plan. It never creates, changes, or deletes AWS
# resources. Exit 3 means a planned prerequisite is absent; any other nonzero
# exit indicates an execution or AWS API error.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  verify-live-plan-prerequisites.sh --scope platform --network-name NAME
  verify-live-plan-prerequisites.sh --scope workload --network-name NAME \
    --cluster-name NAME --kms-alias NAME --session-table NAME

The AWS region and credentials come from the calling environment.
Exit statuses: 0 ready, 3 prerequisite absent, other nonzero error.
USAGE
}

scope=""
network_name=""
cluster_name=""
kms_alias=""
session_table=""

while (( $# > 0 )); do
  case "$1" in
    --scope)
      scope="$2"
      shift 2
      ;;
    --network-name)
      network_name="$2"
      shift 2
      ;;
    --cluster-name)
      cluster_name="$2"
      shift 2
      ;;
    --kms-alias)
      kms_alias="$2"
      shift 2
      ;;
    --session-table)
      session_table="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ "$scope" != 'platform' && "$scope" != 'workload' ]] || [[ -z "$network_name" ]]; then
  usage >&2
  exit 64
fi

if [[ "$scope" == 'workload' ]] && [[ -z "$cluster_name" || -z "$kms_alias" || -z "$session_table" ]]; then
  usage >&2
  exit 64
fi

missing=()

vpc_id="$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=${network_name}" \
  --query 'Vpcs[0].VpcId' \
  --output text)"

if [[ -z "$vpc_id" || "$vpc_id" == 'None' ]]; then
  missing+=("VPC tagged Name=${network_name}")
fi

if [[ "$scope" == 'workload' ]]; then
  cluster_arn="$(aws ecs list-clusters \
    --query "clusterArns[?contains(@, 'cluster/${cluster_name}')] | [0]" \
    --output text)"
  if [[ -z "$cluster_arn" || "$cluster_arn" == 'None' ]]; then
    missing+=("ECS cluster ${cluster_name}")
  fi

  if ! kms_error="$(aws kms describe-key --key-id "$kms_alias" 2>&1 >/dev/null)"; then
    if [[ "$kms_error" == *'NotFoundException'* ]]; then
      missing+=("KMS alias ${kms_alias}")
    else
      printf '%s\n' "$kms_error" >&2
      exit 1
    fi
  fi

  if ! dynamodb_error="$(aws dynamodb describe-table --table-name "$session_table" 2>&1 >/dev/null)"; then
    if [[ "$dynamodb_error" == *'ResourceNotFoundException'* ]]; then
      missing+=("DynamoDB table ${session_table}")
    else
      printf '%s\n' "$dynamodb_error" >&2
      exit 1
    fi
  fi
fi

if (( ${#missing[@]} > 0 )); then
  printf 'DEFERRED: live prerequisite(s) absent: %s\n' "$(IFS=', '; echo "${missing[*]}")" >&2
  exit 3
fi

printf 'READY: live prerequisites exist for the %s plan.\n' "$scope"
