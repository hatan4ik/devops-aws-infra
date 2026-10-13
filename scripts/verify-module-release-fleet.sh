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

# gh_call runs `gh api` and keeps its real HTTP error text (status and message)
# so a token-scope or rate-limit problem is not mistaken for an invariant
# violation. On success the response is in api_output; on failure api_error
# carries the error text.
gh_error_file="$(mktemp "${TMPDIR:-/tmp}/module-release-fleet.XXXXXX")"
trap 'rm -f "$gh_error_file"' EXIT
api_output=''
api_error=''
gh_call() {
  api_output=''
  api_error=''
  if api_output=$(gh api "$@" 2>"$gh_error_file"); then
    return 0
  fi
  # gh prints the message on stderr and the JSON error body on stdout.
  api_error=$(tr '\n' ' ' <"$gh_error_file")
  [[ -n "${api_error// /}" ]] || api_error=$(tr '\n' ' ' <<<"$api_output")
  api_error="${api_error:0:300}"
  api_error="${api_error%"${api_error##*[![:space:]]}"}"
  return 1
}

record_failure() {
  local repository="$1"
  local reason="$2"
  printf 'FAIL: %s: %s\n' "$repository" "$reason" >&2
  failures=$((failures + 1))
}

# Discovery runs before the loop (not as a process substitution) so a failed or
# rate-limited call stops the audit instead of its error body being iterated as
# repository names.
if ! gh_call --paginate "/users/$owner/repos?per_page=100&type=owner" \
  --jq '.[] | select(.name | startswith("aws.modules.")) | .name'; then
  printf 'FAIL: repository discovery for %s failed: %s\n' "$owner" "$api_error" >&2
  exit 1
fi
repositories="$(sort <<<"$api_output")"

while IFS= read -r repository; do
  [[ -n "$repository" ]] || continue
  repository_count=$((repository_count + 1))
  repository_failed=0

  if ! gh_call "repos/$owner/$repository"; then
    record_failure "$repository" "repository metadata is unavailable: $api_error"
    continue
  fi
  repository_json="$api_output"
  default_branch=$(jq -r '.default_branch // empty' <<<"$repository_json")
  if [[ -z "$default_branch" ]]; then
    record_failure "$repository" 'default branch is absent'
    continue
  fi

  if ! gh_call "repos/$owner/$repository/commits/$default_branch" --jq .sha; then
    record_failure "$repository" "cannot resolve $default_branch: $api_error"
    continue
  fi
  main_sha="$api_output"

  # The tags endpoint is not semver-ordered and lists prereleases (for example
  # v1.1.0-rc2 ahead of v1.0.0), while /releases/latest excludes them. Take the
  # highest stable semver tag so both sides compare the same notion of latest.
  if ! gh_call --paginate "repos/$owner/$repository/tags?per_page=100" --jq '.[].name'; then
    record_failure "$repository" "cannot list tags: $api_error"
    continue
  fi
  if ! latest_tag=$(jq -Rrn '[inputs | select(test("^v?[0-9]+\\.[0-9]+\\.[0-9]+$"))]
      | sort_by(ltrimstr("v") | split(".") | map(tonumber))
      | .[-1] // empty' <<<"$api_output"); then
    record_failure "$repository" 'cannot evaluate the tag list'
    continue
  fi
  if [[ -z "$latest_tag" ]]; then
    record_failure "$repository" 'no stable semver tag exists'
    continue
  fi

  if ! gh_call "repos/$owner/$repository/git/ref/tags/$latest_tag"; then
    record_failure "$repository" "cannot resolve tag $latest_tag: $api_error"
    continue
  fi
  tag_reference_json="$api_output"
  tag_object_type=$(jq -r '.object.type // empty' <<<"$tag_reference_json")
  if [[ "$tag_object_type" != 'tag' ]]; then
    record_failure "$repository" "$latest_tag is not an annotated tag"
    continue
  fi

  tag_object_sha=$(jq -r '.object.sha // empty' <<<"$tag_reference_json")
  if ! gh_call "repos/$owner/$repository/git/tags/$tag_object_sha"; then
    record_failure "$repository" "annotated tag object $latest_tag is unavailable: $api_error"
    continue
  fi
  tag_object_json="$api_output"
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

  if ! gh_call "repos/$owner/$repository/releases/latest"; then
    record_failure "$repository" "no published non-prerelease GitHub Release exists: $api_error"
    repository_failed=1
  else
    release_tag=$(jq -r '.tag_name // empty' <<<"$api_output")
    if [[ "$release_tag" != "$latest_tag" ]]; then
      record_failure "$repository" "latest Release $release_tag does not match tag $latest_tag"
      repository_failed=1
    fi
  fi

  if ((repository_failed == 0)); then
    printf 'PASS: %s %s %s\n' "$repository" "$latest_tag" "$main_sha"
  fi
done <<<"$repositories"

if ((repository_count == 0)); then
  printf 'no aws.modules.* repositories were discovered for %s\n' "$owner" >&2
  exit 1
fi

if ((failures > 0)); then
  printf 'FAIL: %d release invariant violation(s) across %d repositories\n' "$failures" "$repository_count" >&2
  exit 1
fi

printf 'PASS: verified current signed releases for %d repositories\n' "$repository_count"
