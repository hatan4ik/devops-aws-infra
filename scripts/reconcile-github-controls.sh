#!/usr/bin/env bash
# Reconcile the remote GitHub controls required by this repository's GitOps
# model. The authenticated GitHub principal needs repository administration.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/reconcile-github-controls.sh [owner/repository]

The script creates/updates the dev, staging, prod, and landing-zone deployment
environments and protects main. It intentionally requires pull requests and
successful checks but defaults to zero required approvals because this personal
repository currently has one administrator. Set GITHUB_REQUIRED_APPROVALS=2
only after adding at least two independent reviewers.
EOF
}

if [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
  usage
  exit 0
fi

repository="${1:-${GITHUB_REPOSITORY:-}}"
if [[ -z "$repository" ]]; then
  repository="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
fi

if [[ ! "$repository" =~ ^[^/]+/[^/]+$ ]]; then
  printf 'repository must be owner/repository, got: %s\n' "$repository" >&2
  exit 64
fi

required_approvals="${GITHUB_REQUIRED_APPROVALS:-0}"
if [[ ! "$required_approvals" =~ ^[0-9]+$ ]]; then
  printf 'GITHUB_REQUIRED_APPROVALS must be a non-negative integer\n' >&2
  exit 64
fi

reviewer_id="$(gh api user --jq .id)"

put_environment() {
  local environment_name="$1"
  local require_reviewer="$2"
  local payload

  if [[ "$require_reviewer" == "yes" ]]; then
    payload="$(jq -cn --argjson reviewer_id "$reviewer_id" '{wait_timer: 0, prevent_self_review: false, reviewers: [{type: "User", id: $reviewer_id}], deployment_branch_policy: {protected_branches: true, custom_branch_policies: false}}')"
  else
    payload="$(jq -cn '{wait_timer: 0, prevent_self_review: false, reviewers: [], deployment_branch_policy: {protected_branches: true, custom_branch_policies: false}}')"
  fi

  printf 'Reconciling GitHub environment %s.\n' "$environment_name"
  printf '%s' "$payload" | gh api --method PUT "repos/$repository/environments/$environment_name" --input - >/dev/null
}

put_environment dev no
put_environment staging yes
put_environment prod yes
put_environment landing-zone yes

code_owner_reviews=false
if (( required_approvals > 0 )); then
  code_owner_reviews=true
fi

protection_payload="$(jq -cn \
  --argjson required_approvals "$required_approvals" \
  --argjson code_owner_reviews "$code_owner_reviews" \
  '{
    required_status_checks: {strict: true, contexts: ["terraform_quality", "GitOps policy checks"]},
    enforce_admins: true,
    required_pull_request_reviews: {
      dismissal_restrictions: {users: [], teams: [], apps: []},
      dismiss_stale_reviews: true,
      require_code_owner_reviews: $code_owner_reviews,
      required_approving_review_count: $required_approvals,
      require_last_push_approval: false,
      bypass_pull_request_allowances: {users: [], teams: [], apps: []}
    },
    restrictions: null,
    required_linear_history: true,
    allow_force_pushes: false,
    allow_deletions: false,
    block_creations: false,
    required_conversation_resolution: true,
    lock_branch: false,
    allow_fork_syncing: true
  }')"

printf 'Protecting main with pull-request, status-check, and history controls.\n'
printf '%s' "$protection_payload" | gh api --method PUT "repos/$repository/branches/main/protection" --input - >/dev/null

printf 'GitHub controls reconciled for %s. Required approvals: %s.\n' "$repository" "$required_approvals"
