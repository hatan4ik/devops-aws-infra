#!/usr/bin/env bash
# Credential-free validation for the GitOps source repository. It initializes
# every Terraform directory with -backend=false and never calls plan/apply.
set -euo pipefail

for required_command in terraform tflint; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command is not available: $required_command" >&2
    exit 69
  }
done

modules=(
  terraform/modules/terraform-aws-vpc-workload
  terraform/modules/terraform-aws-tgw-hub
  terraform/modules/terraform-aws-cognito-userpool
  terraform/modules/internal/state-backend
  terraform/modules/internal/network-regional
  terraform/modules/internal/tgw-vpc-attachment
  terraform/modules/internal/workload-regional
)

roots=(
  terraform/roots/foundation/region-a/shared
  terraform/roots/network/region-a/shared
  terraform/roots/network/region-b/shared
  terraform/roots/workload-dev/region-a/dev
  terraform/roots/workload-dev/region-b/dev
  terraform/roots/workload-staging/region-a/staging
  terraform/roots/workload-staging/region-b/staging
  terraform/roots/workload-prod/region-a/prod
  terraform/roots/workload-prod/region-b/prod
)

terraform fmt -check -recursive -no-color terraform

for directory in "${modules[@]}"; do
  terraform -chdir="$directory" init -backend=false -input=false -no-color
  terraform -chdir="$directory" validate -no-color
  terraform -chdir="$directory" test -no-color
  tflint --chdir="$directory" --init
  tflint --chdir="$directory"
  printf 'PASS: module quality %s\n' "$directory"
done

for directory in "${roots[@]}"; do
  terraform -chdir="$directory" init -backend=false -input=false -no-color
  terraform -chdir="$directory" validate -no-color
  tflint --chdir="$directory" --init
  tflint --chdir="$directory"
  printf 'PASS: root quality %s\n' "$directory"
done
