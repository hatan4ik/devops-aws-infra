#!/usr/bin/env bash
# Verifies the ADR/IaC boundary established by ADRs 0014 and 0017 without AWS access.
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
  docs/adr/0015-adopt-legacy-state-bootstrap.md
  docs/adr/0016-terraform-state-lock-transition.md
  docs/adr/0017-github-oidc-bootstrap-proof.md
  docs/adr/0018-sandbox-network-gitops-delivery.md
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

historical_profile_prefix='AWS-hatan4ik-'
historical_profile="${historical_profile_prefix}gmail"
if git grep -nF -- "$historical_profile"; then
  fail 'a historical named local credential profile remains in source'
fi

delivery_workflow=.github/workflows/terraform-apply.yml
[[ -f "$delivery_workflow" ]] || fail "missing delivery preflight workflow: $delivery_workflow"
oidc_proof_workflow=.github/workflows/oidc-sandbox-proof.yml
sandbox_network_plan_workflow=.github/workflows/sandbox-network-plan.yml
sandbox_network_apply_workflow=.github/workflows/sandbox-network-apply.yml
sandbox_network_drift_workflow=.github/workflows/sandbox-network-drift.yml
credentialed_workflows="$(grep -lEi 'id-token:[[:space:]]*write|configure-aws-credentials' .github/workflows/*.yml || true)"
if [[ -n "$credentialed_workflows" ]]; then
  while IFS= read -r workflow; do
    [[ -n "$workflow" ]] || continue
    case "$workflow" in
      "$oidc_proof_workflow"|"$sandbox_network_plan_workflow"|"$sandbox_network_apply_workflow"|"$sandbox_network_drift_workflow") ;;
      *) fail "unexpected credentialed root workflow: $workflow" ;;
    esac
  done <<< "$credentialed_workflows"
fi

[[ -f "$oidc_proof_workflow" ]] || fail "missing approved OIDC proof workflow: $oidc_proof_workflow"
grep -Fq 'workflow_dispatch:' "$oidc_proof_workflow" || fail 'OIDC proof must be manual-dispatch only'
grep -Fq 'aws sts get-caller-identity' "$oidc_proof_workflow" || fail 'OIDC proof must verify only its STS identity'
if grep -nEi 'terraform|cloudformation|aws[[:space:]].*[[:space:]](create|delete|put|update|attach|detach|run-instances)([[:space:]]|$)' "$oidc_proof_workflow"; then
  fail 'OIDC proof workflow must not include an infrastructure mutation'
fi

[[ -f "$sandbox_network_plan_workflow" ]] || fail "missing sandbox-network plan workflow"
[[ -f "$sandbox_network_apply_workflow" ]] || fail "missing sandbox-network apply workflow"
[[ -f "$sandbox_network_drift_workflow" ]] || fail "missing sandbox-network drift workflow"

grep -Fq 'github.event.pull_request.head.repo.full_name == github.repository' "$sandbox_network_plan_workflow" || fail 'sandbox-network plan must reject fork pull requests'
grep -Fq 'AWS_SANDBOX_NETWORK_PLAN_ROLE_ARN' "$sandbox_network_plan_workflow" || fail 'sandbox-network plan must use its dedicated role variable'
grep -Fq 'terraform plan' "$sandbox_network_plan_workflow" || fail 'sandbox-network plan must produce a Terraform plan'
if grep -nEi 'terraform[[:space:]]+apply' "$sandbox_network_plan_workflow"; then
  fail 'sandbox-network plan workflow must not apply Terraform'
fi

grep -Fq 'workflow_dispatch:' "$sandbox_network_apply_workflow" || fail 'sandbox-network apply must require manual dispatch'
grep -Fq "if: inputs.confirm == 'apply'" "$sandbox_network_apply_workflow" || fail 'sandbox-network apply must require explicit confirmation'
grep -Fq 'environment: dev' "$sandbox_network_apply_workflow" || fail 'sandbox-network apply must use the protected dev environment'
grep -Fq 'AWS_SANDBOX_NETWORK_APPLY_ROLE_ARN' "$sandbox_network_apply_workflow" || fail 'sandbox-network apply must use its dedicated role variable'
grep -Fq 'Require the protected dev environment apply role variable' "$sandbox_network_apply_workflow" || fail 'sandbox-network apply must validate its environment role variable after environment protection applies'
grep -Fq 'terraform apply' "$sandbox_network_apply_workflow" || fail 'sandbox-network apply workflow is missing its controlled apply step'

terraform_apply_workflows="$(grep -lEi 'terraform[[:space:]]+apply' .github/workflows/*.yml || true)"
if [[ -n "$terraform_apply_workflows" ]]; then
  while IFS= read -r workflow; do
    [[ -n "$workflow" ]] || continue
    [[ "$workflow" == "$sandbox_network_apply_workflow" ]] || fail "unexpected Terraform apply workflow: $workflow"
  done <<< "$terraform_apply_workflows"
fi

grep -Fq 'schedule:' "$sandbox_network_drift_workflow" || fail 'sandbox-network drift must be scheduled'
grep -Fq 'AWS_SANDBOX_NETWORK_DRIFT_ROLE_ARN' "$sandbox_network_drift_workflow" || fail 'sandbox-network drift must use its dedicated role variable'
grep -Fq 'Require the protected dev environment drift role variable' "$sandbox_network_drift_workflow" || fail 'sandbox-network drift must validate its environment role variable after environment protection applies'
grep -Fq 'terraform plan -detailed-exitcode' "$sandbox_network_drift_workflow" || fail 'sandbox-network drift must report detected changes'
if grep -nEi 'terraform[[:space:]]+apply' "$sandbox_network_drift_workflow"; then
  fail 'sandbox-network drift workflow must not apply Terraform'
fi

if grep -R -nE --include='*.yml' --include='*.yaml' '[0-9]{12}' .github/workflows; then
  fail 'root workflows must not contain a hard-coded AWS account identifier'
fi

grep -Fq 'only candidate Terraform delivery tree' README.md || fail 'root README does not identify the canonical Terraform tree'

# Canonical source must not carry mutable plans, state, or ad hoc IAM
# permission artefacts. The disabled prototype is deliberately not scanned:
# ADR 0015 retains its historical state artefacts until the approved
# declarative migration evidence permits quarantine or removal.
if find terraform -type f \( -name '*.tfstate' -o -name '*.tfstate.*' -o -name '*.tfplan' -o -name 'required_permissions.txt' \) -print -quit | grep -q .; then
  fail 'canonical Terraform tree contains a state, plan, or ad hoc permission artifact'
fi

printf 'PASS: ADR and Terraform delivery boundary\n'
