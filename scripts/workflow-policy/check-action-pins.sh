#!/usr/bin/env bash
# Reject mutable third-party GitHub Action references in reusable workflows.
set -euo pipefail

workflow_directory="${1:-.github/workflows}"
[[ -d "$workflow_directory" ]] || { echo "workflow directory does not exist: $workflow_directory" >&2; exit 64; }

found_reference=false
while IFS= read -r reference; do
  # Repository-local reusable workflows are source files, not third-party
  # Actions. Their immutable boundary is the caller's protected revision.
  [[ "$reference" == ./* ]] && continue

  found_reference=true
  [[ "$reference" =~ ^[^[:space:]@]+@[0-9a-f]{40}$ ]] || {
    echo "mutable or malformed action reference: $reference" >&2
    exit 1
  }
done < <(
  if command -v rg >/dev/null 2>&1; then
    rg --hidden --no-filename --only-matching --pcre2 'uses:\s*\K[^[:space:]#]+' "$workflow_directory"
  else
    grep -RhoE '^[[:space:]]*uses:[[:space:]]*[^[:space:]#]+' "$workflow_directory" | sed -E 's/^[[:space:]]*uses:[[:space:]]*//'
  fi
)

"$found_reference" || { echo "no third-party action references found in $workflow_directory" >&2; exit 1; }
echo "PASS: every third-party action uses a full 40-character commit SHA"
