#!/usr/bin/env bash
# Reject mutable third-party GitHub Action references in reusable workflows.
set -euo pipefail

workflow_directory="${1:-.github/workflows}"
[[ -d "$workflow_directory" ]] || { echo "workflow directory does not exist: $workflow_directory" >&2; exit 64; }

found_reference=false
while IFS= read -r reference; do
  found_reference=true
  [[ "$reference" =~ ^[^[:space:]@]+@[0-9a-f]{40}$ ]] || {
    echo "mutable or malformed action reference: $reference" >&2
    exit 1
  }
done < <(rg --hidden --no-filename --only-matching --pcre2 'uses:\s*\K[^[:space:]#]+' "$workflow_directory")

"$found_reference" || { echo "no third-party action references found in $workflow_directory" >&2; exit 1; }
echo "PASS: every third-party action uses a full 40-character commit SHA"
