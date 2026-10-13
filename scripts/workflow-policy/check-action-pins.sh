#!/usr/bin/env bash
# Reject mutable third-party GitHub Action references in reusable workflows.
set -euo pipefail

workflow_directory="${1:-.github/workflows}"
[[ -d "$workflow_directory" ]] || { echo "workflow directory does not exist: $workflow_directory" >&2; exit 64; }

# One extractor for every case: a `uses:` key that starts a line, optionally as
# a list item (`- uses:`). Commented lines never match because `#` is not
# allowed before the key. Only workflow YAML is scanned.
uses_pattern='^[[:space:]]*(-[[:space:]]+)?uses:'
double_quoted='^"([^"]*)"'
single_quoted="^'([^']*)'"
unquoted='^([^[:space:]#]+)'

# A command substitution (not a process substitution) so a failing find aborts
# the script under set -e instead of looking like "no references".
workflow_files="$(find "$workflow_directory" -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)"

local_reference_count=0
third_party_count=0
offender_count=0

while IFS= read -r workflow_file; do
  [[ -n "$workflow_file" ]] || continue

  # grep exits 1 when the file has no `uses:` line; any other non-zero status
  # is a real error that must not be reported as "no references".
  grep_status=0
  matches="$(grep -nE "$uses_pattern" "$workflow_file")" || grep_status=$?
  if ((grep_status > 1)); then
    echo "cannot scan workflow file: $workflow_file" >&2
    exit 1
  fi
  [[ -n "$matches" ]] || continue

  while IFS= read -r match; do
    line_number="${match%%:*}"
    value="${match#*:}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value#-}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value#uses:}"
    value="${value#"${value%%[![:space:]]*}"}"

    if [[ "$value" =~ $double_quoted ]]; then
      reference="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ $single_quoted ]]; then
      reference="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ $unquoted ]]; then
      reference="${BASH_REMATCH[1]}"
    else
      reference=""
    fi

    # Repository-local reusable workflows are source files, not third-party
    # Actions. Their immutable boundary is the caller's protected revision.
    if [[ "$reference" == ./* ]]; then
      local_reference_count=$((local_reference_count + 1))
      continue
    fi

    third_party_count=$((third_party_count + 1))
    if [[ ! "$reference" =~ ^[^[:space:]@]+@[0-9a-f]{40}$ ]]; then
      echo "mutable or malformed action reference: ${reference:-<empty>} ($workflow_file:$line_number)" >&2
      offender_count=$((offender_count + 1))
    fi
  done <<<"$matches"
done <<<"$workflow_files"

if ((offender_count > 0)); then
  echo "$offender_count mutable or malformed action reference(s) found in $workflow_directory" >&2
  exit 1
fi

if ((third_party_count == 0)); then
  if ((local_reference_count > 0)); then
    echo "only repository-local ./ workflow references found in $workflow_directory; no third-party action references to verify" >&2
  else
    echo "no third-party action references found in $workflow_directory" >&2
  fi
  exit 1
fi
echo "PASS: every third-party action uses a full 40-character commit SHA"
