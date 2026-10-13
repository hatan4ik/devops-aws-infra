#!/usr/bin/env bash
# Reconcile the remote GitHub controls required by this repository's GitOps
# model. The authenticated GitHub principal needs repository administration.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/reconcile-github-controls.sh [--dry-run] [owner/repository]

The script creates/updates the dev, staging, prod, and landing-zone deployment
environments and protects main. It intentionally requires pull requests and
successful checks but defaults to zero required approvals because this personal
repository currently has one administrator. Set GITHUB_REQUIRED_APPROVALS=2
only after adding at least two independent reviewers.

The authenticated GitHub user becomes the sole required reviewer of staging,
prod, and landing-zone (replacing any existing reviewer list); the script prints
who that is before writing. The required status check names are verified against
the job names in .github/workflows/*.yml before anything is written.

  --dry-run   Print every PUT (path and payload) without sending it. GET reads
              still run, so the authenticated principal and repository owner
              type are resolved for real.
EOF
}

dry_run=false
repository_arg=""
for argument in "$@"; do
  case "$argument" in
    --help|-h) usage; exit 0 ;;
    --dry-run) dry_run=true ;;
    -*) printf 'unknown option: %s\n' "$argument" >&2; usage >&2; exit 64 ;;
    *)
      if [[ -n "$repository_arg" ]]; then
        printf 'unexpected argument: %s\n' "$argument" >&2
        usage >&2
        exit 64
      fi
      repository_arg="$argument"
      ;;
  esac
done

repository="${repository_arg:-${GITHUB_REPOSITORY:-}}"
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
reviewer_login="$(gh api user --jq .login)"
owner_type="$(gh api "repos/$repository" --jq .owner.type)"
case "$owner_type" in
  Organization|User) ;;
  *) printf 'unsupported GitHub repository owner type: %s\n' "$owner_type" >&2; exit 65 ;;
esac

# Branch protection requires these exact check contexts. A context that no job
# reports blocks main permanently (strict: true), so verify each one against the
# job names (or ids, for unnamed jobs) in this checkout before writing anything.
required_contexts=("terraform_quality" "GitOps policy checks")
workflows_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/.github/workflows"
if ! workflow_job_names="$(awk '
  function flush() { if (have && !named) print id; have = 0 }
  FNR == 1 { flush(); injobs = 0 }
  /^jobs:[[:space:]]*(#.*)?$/ { injobs = 1; next }
  injobs && /^[^[:space:]#]/ { flush(); injobs = 0 }
  injobs && /^  [^[:space:]#][^:]*:[[:space:]]*(#.*)?$/ { flush(); id = $0; sub(/^  /, "", id); sub(/:.*$/, "", id); have = 1; named = 0; next }
  injobs && /^    name:/ { v = $0; sub(/^    name:[[:space:]]*/, "", v); sub(/[[:space:]]+#.*$/, "", v); sub("^[\"\047]", "", v); sub("[\"\047]$", "", v); print v; named = 1 }
  END { flush() }
' "$workflows_dir"/*.yml)"; then
  printf 'cannot read workflow job names from %s\n' "$workflows_dir" >&2
  exit 66
fi
for required_context in "${required_contexts[@]}"; do
  if ! printf '%s\n' "$workflow_job_names" | grep -qxF -- "$required_context"; then
    printf 'required status check "%s" is not a job name in %s/*.yml; refusing to protect main with a check that never reports. Nothing was written.\n' "$required_context" "$workflows_dir" >&2
    exit 66
  fi
done
contexts_json="$(printf '%s\n' "${required_contexts[@]}" | jq -R . | jq -cs .)"

# The PUT replaces the whole reviewer list, so name the principal being set.
printf 'Sole required reviewer for staging, prod, landing-zone: %s (id %s). This is the authenticated user and prevent_self_review is false.\n' "$reviewer_login" "$reviewer_id"

# Environment and branch-protection writes are not transactional: remember what
# was applied so a mid-run failure says exactly what changed.
applied=""
report_partial_apply() {
  local status=$?
  if (( status != 0 )) && [[ -n "$applied" ]]; then
    printf 'FAILED after applying: %s. The remaining controls were not applied; PUTs are idempotent, so re-run to converge.\n' "$applied" >&2
  fi
}
trap report_partial_apply EXIT

github_put() {
  local label="$1" api_path="$2" payload="$3"
  if [[ "$dry_run" == "true" ]]; then
    printf 'DRY-RUN: would PUT %s (%s)\n  %s\n' "$api_path" "$label" "$payload"
    return 0
  fi
  printf '%s' "$payload" | gh api --method PUT "$api_path" --input - >/dev/null
  applied="${applied:+$applied, }$label"
}

put_environment() {
  local environment_name="$1"
  local require_reviewer="$2"
  local payload

  if [[ "$require_reviewer" == "yes" ]]; then
    payload="$(jq -cn --argjson reviewer_id "$reviewer_id" '{wait_timer: 0, prevent_self_review: false, reviewers: [{type: "User", id: $reviewer_id}], deployment_branch_policy: {protected_branches: true, custom_branch_policies: false}}')"
  else
    payload="$(jq -cn '{wait_timer: 0, prevent_self_review: false, reviewers: [], deployment_branch_policy: {protected_branches: true, custom_branch_policies: false}}')"
  fi

  if [[ "$dry_run" != "true" ]]; then
    printf 'Reconciling GitHub environment %s.\n' "$environment_name"
  fi
  github_put "environment $environment_name" "repos/$repository/environments/$environment_name" "$payload"
}

put_environment dev no
put_environment staging yes
put_environment prod yes
put_environment landing-zone yes

code_owner_reviews=false
if (( required_approvals > 0 )); then
  code_owner_reviews=true
fi

if [[ "$owner_type" == "Organization" ]]; then
  review_policy="$(jq -cn \
    --argjson required_approvals "$required_approvals" \
    --argjson code_owner_reviews "$code_owner_reviews" \
    '{
      dismissal_restrictions: {users: [], teams: [], apps: []},
      dismiss_stale_reviews: true,
      require_code_owner_reviews: $code_owner_reviews,
      required_approving_review_count: $required_approvals,
      require_last_push_approval: false,
      bypass_pull_request_allowances: {users: [], teams: [], apps: []}
    }')"
else
  # GitHub's branch-protection API rejects user/team restriction fields on a
  # personal repository, including empty arrays.
  review_policy="$(jq -cn \
    --argjson required_approvals "$required_approvals" \
    --argjson code_owner_reviews "$code_owner_reviews" \
    '{
      dismiss_stale_reviews: true,
      require_code_owner_reviews: $code_owner_reviews,
      required_approving_review_count: $required_approvals,
      require_last_push_approval: false
    }')"
fi

protection_payload="$(jq -cn \
  --argjson review_policy "$review_policy" \
  --argjson contexts "$contexts_json" \
  '{
    required_status_checks: {strict: true, contexts: $contexts},
    enforce_admins: true,
    required_pull_request_reviews: $review_policy,
    restrictions: null,
    required_linear_history: true,
    allow_force_pushes: false,
    allow_deletions: false,
    block_creations: false,
    required_conversation_resolution: true,
    lock_branch: false,
    allow_fork_syncing: true
  }')"

if [[ "$dry_run" != "true" ]]; then
  printf 'Protecting main with pull-request, status-check, and history controls.\n'
fi
github_put "branch protection main" "repos/$repository/branches/main/protection" "$protection_payload"

if [[ "$dry_run" == "true" ]]; then
  printf 'DRY-RUN complete for %s: no changes were sent to GitHub. Required approvals would be: %s.\n' "$repository" "$required_approvals"
else
  printf 'GitHub controls reconciled for %s. Required approvals: %s.\n' "$repository" "$required_approvals"
fi
