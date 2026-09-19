#!/usr/bin/env bash
# Verifies the ADR/IaC boundary established by ADR 0014 without AWS access.
set -euo pipefail

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

active_adrs=(
  docs/adr/0001-control-tower-account-vending.md
  docs/adr/0002-regional-availability-and-data.md
  docs/adr/0003-segmented-tgw-ipam-and-encryption.md
  docs/adr/0004-edge-ingress-and-egress.md
  docs/adr/0005-hybrid-connectivity.md
  docs/adr/0006-identity-and-authorization.md
  docs/adr/0007-compute-and-data.md
  docs/adr/0008-security-and-state.md
  docs/adr/0009-observability-and-sre.md
  docs/adr/0010-repository-and-module-topology.md
  docs/adr/0011-cognito-mrr-provider-boundary.md
  docs/adr/0012-oidc-gated-terraform-delivery.md
  docs/adr/0013-layered-verification-no-automatic-fault-injection.md
  docs/adr/0014-canonical-architecture-and-iac-boundary.md
)

superseded_adrs=(
  docs/adr/0001-account-structure.md
  docs/adr/0002-multi-region-strategy.md
  docs/adr/0003-compute-platform.md
  docs/adr/0004-identity-provider.md
  docs/adr/0005-egress-inspection.md
  docs/adr/0006-edge-ingress.md
  docs/adr/0007-fine-grained-auth.md
  docs/adr/0008-observability.md
  docs/adr/0009-repository-strategy.md
)

prototype_roots=(
  roots/shared-services/us-east-2/prod
  roots/workload-app/us-east-2/dev
  roots/workload-app/us-east-2/staging
  roots/workload-app/us-east-2/prod
)

prototype_modules=(
  modules/aws-cloudfront-alb
  modules/aws-cognito-auth
  modules/aws-ecs-fargate
  modules/aws-tf-state-backend
  modules/aws-vpc-workload
)

fail() {
  printf 'ADR boundary check failed: %s\n' "$*" >&2
  exit 1
}

for adr in "${active_adrs[@]}"; do
  [[ -f "$adr" ]] || fail "missing active ADR: $adr"
done

for adr in "${superseded_adrs[@]}"; do
  [[ -f "$adr" ]] || fail "missing historical ADR: $adr"
  grep -Fq 'Superseded by [ADR 0014]' "$adr" || fail "historical ADR is not superseded: $adr"
done

for root in "${prototype_roots[@]}"; do
  guard="$root/prototype_guard.tf"
  [[ -f "$guard" ]] || fail "missing disabled-prototype guard: $guard"
  grep -Fq 'terraform.workspace != terraform.workspace' "$guard" || fail "prototype guard does not fail plans: $guard"
done

for module in "${prototype_modules[@]}"; do
  guard="$module/prototype_guard.tf"
  [[ -f "$guard" ]] || fail "missing disabled-prototype guard: $guard"
  grep -Fq 'terraform.workspace != terraform.workspace' "$guard" || fail "prototype guard does not fail plans: $guard"
done

if grep -R -nE --include='*.tf' 'backend[[:space:]]+"s3"|profile[[:space:]]*=' roots; then
  fail 'disabled prototype roots must not configure an S3 backend or local profile'
fi

if grep -R -nE --include='*.tf' 'provider[[:space:]]+"aws"' roots; then
  fail 'disabled prototype roots must not configure an AWS provider'
fi

if git grep -nF -- 'AWS-hatan4ik-gmail'; then
  fail 'a historical named local credential profile remains in source'
fi

grep -Fq 'only candidate Terraform delivery tree' README.md || fail 'root README does not identify the canonical Terraform tree'

printf 'PASS: ADR and Terraform delivery boundary\n'
