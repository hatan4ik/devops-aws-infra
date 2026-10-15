#!/usr/bin/env bash
set -euo pipefail

case "${AWS_ENDPOINT_URL:-}" in
  http://localhost:4566|http://127.0.0.1:4566) ;;
  *)
    echo "Refusing to run: source tools/floci/env.sh so AWS_ENDPOINT_URL targets local Floci." >&2
    exit 1
    ;;
esac

run_id="$(date +%s)-$$"
queue_name="floci-smoke-${run_id}"
cluster_name="floci-smoke-${run_id}"
queue_url=""
cluster_created=false

cleanup() {
  if [ -n "$queue_url" ]; then
    aws sqs delete-queue --queue-url "$queue_url" >/dev/null || true
  fi
  if [ "$cluster_created" = true ]; then
    aws ecs delete-cluster --cluster "$cluster_name" >/dev/null || true
  fi
}
trap cleanup EXIT

aws sts get-caller-identity
queue_url="$(aws sqs create-queue --queue-name "$queue_name" --query QueueUrl --output text)"
aws ecs create-cluster --cluster-name "$cluster_name" >/dev/null
cluster_created=true
aws ecs describe-clusters --clusters "$cluster_name" --query 'clusters[0].status' --output text | grep -qx ACTIVE

echo "Floci smoke test passed: SQS and ECS are reachable through ${AWS_ENDPOINT_URL}."
