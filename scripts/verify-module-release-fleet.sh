#!/usr/bin/env bash
# Verifies the immutable release invariant for every public aws.modules.* repo.
set -euo pipefail

owner="${MODULE_OWNER:-hatan4ik}"

for required_command in gh jq sort; do
  command -v "$required_command" >/dev/null 2>&1 || {
    printf 'required command is not available: %s\n' "$required_command" >&2
    exit 69
  }
done

failures=0
repository_count=0

record_failure() {
  local repository="$1"
  local reason="$2"
  printf 'FAIL: %s: %s\n' "$repository" "$reason" >&2
  failures=$((failures + 1))
}

while IFS= read -r repository; do
  [[ -n "$repository" ]] || continue
  repository_count=$((repository_count + 1))
  repository_failed=0

  if ! repository_json=$(gh api "repos/$owner/$repository" 2>/dev/null); then
    record_failure "$repository" 'repository metadata is unavailable'
    continue
  fi
  default_branch=$(jq -r '.default_branch // empty' <<<"$repository_json")
  if [[ -z "$default_branch" ]]; then
    record_failure "$repository" 'default branch is absent'
    continue
  fi

  if ! main_sha=$(gh api "repos/$owner/$repository/commits/$default_branch" --jq .sha 2>/dev/null); then
    record_failure "$repository" "cannot resolve $default_branch"
    continue
  fi
  latest_tag=$(gh api "repos/$owner/$repository/tags?per_page=1" --jq '.[0].name // empty' 2>/dev/null || true)
  if [[ -z "$latest_tag" ]]; then
    record_failure "$repository" 'no tag exists'
    continue
  fi

  if ! tag_reference_json=$(gh api "repos/$owner/$repository/git/ref/tags/$latest_tag" 2>/dev/null); then
    record_failure "$repository" "cannot resolve tag $latest_tag"
    continue
  fi
  tag_object_type=$(jq -r '.object.type // empty' <<<"$tag_reference_json")
  if [[ "$tag_object_type" != 'tag' ]]; then
    record_failure "$repository" "$latest_tag is not an annotated tag"
    continue
  fi

  tag_object_sha=$(jq -r '.object.sha // empty' <<<"$tag_reference_json")
  if ! tag_object_json=$(gh api "repos/$owner/$repository/git/tags/$tag_object_sha" 2>/dev/null); then
    record_failure "$repository" "annotated tag object $latest_tag is unavailable"
    continue
  fi
  tag_target_sha=$(jq -r '.object.sha // empty' <<<"$tag_object_json")
  tag_verified=$(jq -r '.verification.verified // false' <<<"$tag_object_json")
  if [[ "$tag_verified" != 'true' ]]; then
    record_failure "$repository" "$latest_tag does not have a GitHub-verified signature"
    repository_failed=1
  fi
  if [[ "$tag_target_sha" != "$main_sha" ]]; then
    record_failure "$repository" "$latest_tag does not point at current $default_branch"
    repository_failed=1
  fi

  if ! release_json=$(gh api "repos/$owner/$repository/releases/latest" 2>/dev/null); then
    record_failure "$repository" 'no published non-prerelease GitHub Release exists'
    repository_failed=1
  else
    release_tag=$(jq -r '.tag_name // empty' <<<"$release_json")
    if [[ "$release_tag" != "$latest_tag" ]]; then
      record_failure "$repository" "latest Release $release_tag does not match tag $latest_tag"
      repository_failed=1
    fi
  fi

  if ((repository_failed == 0)); then
    printf 'PASS: %s %s %s\n' "$repository" "$latest_tag" "$main_sha"
  fi
done < <(
  gh api --paginate "/users/$owner/repos?per_page=100&type=owner" \
    --jq '.[] | select(.name | startswith("aws.modules.")) | .name' | sort
)

if ((repository_count == 0)); then
  printf 'no aws.modules.* repositories were discovered for %s\n' "$owner" >&2
  exit 1
fi

if ((failures > 0)); then
  printf 'FAIL: %d release invariant violation(s) across %d repositories\n' "$failures" "$repository_count" >&2
  exit 1
fi

printf 'PASS: verified current signed releases for %d repositories\n' "$repository_count"
