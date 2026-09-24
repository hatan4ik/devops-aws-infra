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
  docs/adr/0019-direct-organizations-account-vending.md
  docs/adr/0020-cognito-mrr-cloudformation-ownership.md
  docs/adr/0021-sandbox-platform-core-single-account.md
  docs/adr/0022-terraform-owned-sandbox-delivery-identity.md
)

fail() {
  printf 'ADR boundary check failed: %s\n' "$*" >&2
  exit 1
}

for adr in "${active_adrs[@]}"; do
  [[ -f "$adr" ]] || fail "missing active ADR: $adr"
done

for retired_path in \
  archive \
  infra/candidates \
  reference \
  docs/book \
  docs/architecture \
  docs/delivery \
  docs/reference \
  docs/reviews; do
  [[ ! -e "$retired_path" ]] || fail "retired source path must not return: $retired_path"
done

historical_profile_prefix='AWS-hatan4ik-'
historical_profile="${historical_profile_prefix}gmail"
if git grep -nF -- "$historical_profile"; then
  fail 'a historical named local credential profile remains in source'
fi

policy_workflow=.github/workflows/terraform-pr.yml
active_root_context=infra/active/root-context.yaml
[[ -f "$policy_workflow" ]] || fail "missing GitOps policy workflow: $policy_workflow"
[[ -f "$active_root_context" ]] || fail "missing active root naming and tag context: $active_root_context"
grep -Fq 'repository: hatan4ik/devops-aws-infra' "$active_root_context" || fail 'active root context must identify this repository'
oidc_proof_workflow=.github/workflows/oidc-sandbox-proof.yml
sandbox_network_plan_workflow=.github/workflows/sandbox-network-plan.yml
sandbox_network_apply_workflow=.github/workflows/sandbox-network-apply.yml
sandbox_network_drift_workflow=.github/workflows/sandbox-network-drift.yml
sandbox_platform_plan_workflow=.github/workflows/sandbox-platform-plan.yml
sandbox_platform_apply_workflow=.github/workflows/sandbox-platform-apply.yml
sandbox_platform_drift_workflow=.github/workflows/sandbox-platform-drift.yml
sandbox_workload_plan_workflow=.github/workflows/sandbox-workload-plan.yml
sandbox_workload_apply_workflow=.github/workflows/sandbox-workload-apply.yml
sandbox_workload_drift_workflow=.github/workflows/sandbox-workload-drift.yml
sandbox_delivery_iam_plan_workflow=.github/workflows/sandbox-delivery-iam-plan.yml
sandbox_delivery_iam_apply_workflow=.github/workflows/sandbox-delivery-iam-apply.yml
sandbox_delivery_iam_drift_workflow=.github/workflows/sandbox-delivery-iam-drift.yml
organization_plan_workflow=.github/workflows/organization-plan.yml
organization_apply_workflow=.github/workflows/organization-apply.yml
organization_drift_workflow=.github/workflows/organization-drift.yml
reusable_plan_workflow=.github/workflows/_terraform-root-plan.yml
reusable_apply_workflow=.github/workflows/_terraform-root-apply.yml
reusable_drift_workflow=.github/workflows/_terraform-root-drift.yml
credentialed_workflows="$(grep -lEi 'id-token:[[:space:]]*write|configure-aws-credentials' .github/workflows/*.yml || true)"
if [[ -n "$credentialed_workflows" ]]; then
  while IFS= read -r workflow; do
    [[ -n "$workflow" ]] || continue
    case "$workflow" in
      "$oidc_proof_workflow"|"$sandbox_network_plan_workflow"|"$sandbox_network_apply_workflow"|"$sandbox_network_drift_workflow"|"$sandbox_platform_plan_workflow"|"$sandbox_platform_apply_workflow"|"$sandbox_platform_drift_workflow"|"$sandbox_workload_plan_workflow"|"$sandbox_workload_apply_workflow"|"$sandbox_workload_drift_workflow"|"$sandbox_delivery_iam_plan_workflow"|"$sandbox_delivery_iam_apply_workflow"|"$sandbox_delivery_iam_drift_workflow"|"$organization_plan_workflow"|"$organization_apply_workflow"|"$organization_drift_workflow"|"$reusable_plan_workflow"|"$reusable_apply_workflow"|"$reusable_drift_workflow") ;;
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
[[ -f "$sandbox_platform_plan_workflow" ]] || fail "missing sandbox-platform plan workflow"
[[ -f "$sandbox_platform_apply_workflow" ]] || fail "missing sandbox-platform apply workflow"
[[ -f "$sandbox_platform_drift_workflow" ]] || fail "missing sandbox-platform drift workflow"
[[ -f "$sandbox_workload_plan_workflow" ]] || fail "missing sandbox-workload plan workflow"
[[ -f "$sandbox_workload_apply_workflow" ]] || fail "missing sandbox-workload apply workflow"
[[ -f "$sandbox_workload_drift_workflow" ]] || fail "missing sandbox-workload drift workflow"
[[ -f "$sandbox_delivery_iam_plan_workflow" ]] || fail "missing sandbox-delivery-iam plan workflow"
[[ -f "$sandbox_delivery_iam_apply_workflow" ]] || fail "missing sandbox-delivery-iam apply workflow"
[[ -f "$sandbox_delivery_iam_drift_workflow" ]] || fail "missing sandbox-delivery-iam drift workflow"
[[ -f "$organization_plan_workflow" ]] || fail "missing organization plan workflow"
[[ -f "$organization_apply_workflow" ]] || fail "missing organization apply workflow"
[[ -f "$organization_drift_workflow" ]] || fail "missing organization drift workflow"
[[ -f "$reusable_plan_workflow" ]] || fail "missing reusable Terraform plan workflow"
[[ -f "$reusable_apply_workflow" ]] || fail "missing reusable Terraform apply workflow"
[[ -f "$reusable_drift_workflow" ]] || fail "missing reusable Terraform drift workflow"

grep -Fq 'github.event.pull_request.head.repo.full_name == github.repository' "$reusable_plan_workflow" || fail 'reusable plan must reject fork pull requests'
grep -Fq 'terraform plan' "$reusable_plan_workflow" || fail 'reusable plan must produce a Terraform plan'
if grep -nEi 'terraform[[:space:]]+apply' "$reusable_plan_workflow"; then
  fail 'reusable plan must not apply Terraform'
fi
grep -Fq 'github.event.repository.default_branch' "$reusable_apply_workflow" || fail 'reusable apply must check out protected default-branch source'
grep -Fq 'terraform apply' "$reusable_apply_workflow" || fail 'reusable apply workflow is missing its controlled apply step'
grep -Fq 'terraform plan -detailed-exitcode' "$reusable_drift_workflow" || fail 'reusable drift must report detected changes'
if grep -nEi 'terraform[[:space:]]+apply' "$reusable_drift_workflow"; then
  fail 'reusable drift must not apply Terraform'
fi

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

# Terraform apply is implemented only in reusable_apply_workflow, which was
# checked above. Caller comments intentionally describe that delegation.

grep -Fq 'schedule:' "$sandbox_network_drift_workflow" || fail 'sandbox-network drift must be scheduled'
grep -Fq 'AWS_SANDBOX_NETWORK_DRIFT_ROLE_ARN' "$sandbox_network_drift_workflow" || fail 'sandbox-network drift must use its dedicated role variable'
grep -Fq 'Require the protected dev environment drift role variable' "$sandbox_network_drift_workflow" || fail 'sandbox-network drift must validate its environment role variable after environment protection applies'
grep -Fq 'terraform plan -detailed-exitcode' "$sandbox_network_drift_workflow" || fail 'sandbox-network drift must report detected changes'
if grep -nEi 'terraform[[:space:]]+apply' "$sandbox_network_drift_workflow"; then
  fail 'sandbox-network drift workflow must not apply Terraform'
fi

grep -Fq 'github.event.pull_request.head.repo.full_name == github.repository' "$sandbox_platform_plan_workflow" || fail 'sandbox-platform plan must reject fork pull requests'
grep -Fq 'AWS_SANDBOX_PLATFORM_PLAN_ROLE_ARN' "$sandbox_platform_plan_workflow" || fail 'sandbox-platform plan must use its dedicated role variable'
grep -Fq 'terraform plan' "$sandbox_platform_plan_workflow" || fail 'sandbox-platform plan must produce a Terraform plan'
if grep -nEi 'terraform[[:space:]]+apply' "$sandbox_platform_plan_workflow"; then
  fail 'sandbox-platform plan must not apply Terraform'
fi

grep -Fq 'workflow_dispatch:' "$sandbox_platform_apply_workflow" || fail 'sandbox-platform apply must require manual dispatch'
grep -Fq "if: inputs.confirm == 'apply'" "$sandbox_platform_apply_workflow" || fail 'sandbox-platform apply must require explicit confirmation'
grep -Fq 'environment: dev' "$sandbox_platform_apply_workflow" || fail 'sandbox-platform apply must use the protected dev environment'
grep -Fq 'AWS_SANDBOX_PLATFORM_APPLY_ROLE_ARN' "$sandbox_platform_apply_workflow" || fail 'sandbox-platform apply must use its dedicated role variable'
grep -Fq 'Require the protected dev environment apply role variable' "$sandbox_platform_apply_workflow" || fail 'sandbox-platform apply must validate its environment role variable after environment protection applies'
grep -Fq 'terraform apply' "$sandbox_platform_apply_workflow" || fail 'sandbox-platform apply workflow is missing its controlled apply step'

grep -Fq 'schedule:' "$sandbox_platform_drift_workflow" || fail 'sandbox-platform drift must be scheduled'
grep -Fq 'AWS_SANDBOX_PLATFORM_DRIFT_ROLE_ARN' "$sandbox_platform_drift_workflow" || fail 'sandbox-platform drift must use its dedicated role variable'
grep -Fq 'Require the protected dev environment drift role variable' "$sandbox_platform_drift_workflow" || fail 'sandbox-platform drift must validate its environment role variable after environment protection applies'
grep -Fq 'terraform plan -detailed-exitcode' "$sandbox_platform_drift_workflow" || fail 'sandbox-platform drift must report detected changes'
if grep -nEi 'terraform[[:space:]]+apply' "$sandbox_platform_drift_workflow"; then
  fail 'sandbox-platform drift must not apply Terraform'
fi

grep -Fq 'github.event.pull_request.head.repo.full_name == github.repository' "$sandbox_workload_plan_workflow" || fail 'sandbox-workload plan must reject fork pull requests'
grep -Fq 'AWS_SANDBOX_WORKLOAD_PLAN_ROLE_ARN' "$sandbox_workload_plan_workflow" || fail 'sandbox-workload plan must use its dedicated role variable'
grep -Fq 'terraform plan' "$sandbox_workload_plan_workflow" || fail 'sandbox-workload plan must produce a Terraform plan'
if grep -nEi 'terraform[[:space:]]+apply' "$sandbox_workload_plan_workflow"; then
  fail 'sandbox-workload plan must not apply Terraform'
fi

grep -Fq 'workflow_dispatch:' "$sandbox_workload_apply_workflow" || fail 'sandbox-workload apply must require manual dispatch'
grep -Fq "if: inputs.confirm == 'apply'" "$sandbox_workload_apply_workflow" || fail 'sandbox-workload apply must require explicit confirmation'
grep -Fq 'environment: dev' "$sandbox_workload_apply_workflow" || fail 'sandbox-workload apply must use the protected dev environment'
grep -Fq 'AWS_SANDBOX_WORKLOAD_APPLY_ROLE_ARN' "$sandbox_workload_apply_workflow" || fail 'sandbox-workload apply must use its dedicated role variable'
grep -Fq 'Require the protected dev environment workload apply role variable' "$sandbox_workload_apply_workflow" || fail 'sandbox-workload apply must validate its environment role variable after environment protection applies'
grep -Fq 'terraform apply' "$sandbox_workload_apply_workflow" || fail 'sandbox-workload apply workflow is missing its controlled apply step'

grep -Fq 'schedule:' "$sandbox_workload_drift_workflow" || fail 'sandbox-workload drift must be scheduled'
grep -Fq 'AWS_SANDBOX_WORKLOAD_DRIFT_ROLE_ARN' "$sandbox_workload_drift_workflow" || fail 'sandbox-workload drift must use its dedicated role variable'
grep -Fq 'Require the protected dev environment workload drift role variable' "$sandbox_workload_drift_workflow" || fail 'sandbox-workload drift must validate its environment role variable after environment protection applies'
grep -Fq 'terraform plan -detailed-exitcode' "$sandbox_workload_drift_workflow" || fail 'sandbox-workload drift must report detected changes'
if grep -nEi 'terraform[[:space:]]+apply' "$sandbox_workload_drift_workflow"; then
  fail 'sandbox-workload drift must not apply Terraform'
fi

grep -Fq 'github.event.pull_request.head.repo.full_name == github.repository' "$organization_plan_workflow" || fail 'organization plan must reject fork pull requests'
grep -Fq 'AWS_ORGANIZATION_PLAN_ROLE_ARN' "$organization_plan_workflow" || fail 'organization plan must use its dedicated role variable'
grep -Fq 'terraform plan' "$organization_plan_workflow" || fail 'organization plan must produce a Terraform plan'
if grep -nEi 'terraform[[:space:]]+apply' "$organization_plan_workflow"; then
  fail 'organization plan workflow must not apply Terraform'
fi

grep -Fq 'workflow_dispatch:' "$organization_apply_workflow" || fail 'organization apply must require manual dispatch'
grep -Fq "if: inputs.confirm == 'apply'" "$organization_apply_workflow" || fail 'organization apply must require explicit confirmation'
grep -Fq 'environment: landing-zone' "$organization_apply_workflow" || fail 'organization apply must use the protected landing-zone environment'
grep -Fq 'AWS_ORGANIZATION_LANDING_ZONE_ROLE_ARN' "$organization_apply_workflow" || fail 'organization apply must use its dedicated role variable'
grep -Fq 'github.event.repository.default_branch' "$organization_apply_workflow" || fail 'organization apply must check out protected default-branch source'
grep -Fq 'terraform apply' "$organization_apply_workflow" || fail 'organization apply workflow is missing its controlled apply step'

grep -Fq 'schedule:' "$organization_drift_workflow" || fail 'organization drift must be scheduled'
grep -Fq 'AWS_ORGANIZATION_DRIFT_ROLE_ARN' "$organization_drift_workflow" || fail 'organization drift must use its dedicated role variable'
grep -Fq 'terraform plan -detailed-exitcode' "$organization_drift_workflow" || fail 'organization drift must report detected changes'
if grep -nEi 'terraform[[:space:]]+apply' "$organization_drift_workflow"; then
  fail 'organization drift workflow must not apply Terraform'
fi

if grep -R -nE --include='*.yml' --include='*.yaml' '[0-9]{12}' .github/workflows; then
  fail 'root workflows must not contain a hard-coded AWS account identifier'
fi

grep -Fq 'single GitOps repository' README.md || fail 'root README does not identify the canonical delivery repository'

# Active source must not carry mutable plans, state, or ad hoc IAM permission
# artefacts.
if find infra -type f \( -name '*.tfstate' -o -name '*.tfstate.*' -o -name '*.tfplan' -o -name 'required_permissions.txt' \) -print -quit | grep -q .; then
  fail 'canonical Terraform tree contains a state, plan, or ad hoc permission artifact'
fi

for naming_root in \
  infra/active/roots/sandbox-network/us-east-2/dev \
  infra/active/roots/sandbox-platform/us-east-2/dev \
  infra/active/roots/sandbox-workload/us-east-2/dev; do
  grep -Eq 'aws\.modules\.naming\.git\?ref=[0-9a-f]{40}' "$naming_root/main.tf" || fail "active root does not use an immutable naming module commit: $naming_root"
  grep -Fq 'module.naming.tags' "$naming_root/providers.tf" || fail "active root does not apply canonical provider tags: $naming_root"
done

while IFS= read -r module_source; do
  [[ "$module_source" =~ \?ref=[0-9a-f]{40}\" ]] || fail "external module source is not pinned to a full commit SHA: $module_source"
done < <(git grep -nE 'source[[:space:]]*=[[:space:]]*"git::https://github\.com/hatan4ik/aws\.modules\.' -- infra)

printf 'PASS: ADR and Terraform delivery boundary\n'
