#!/usr/bin/env bash
set -euo pipefail

# Run Terraform only against the local Floci endpoint.  The catalog never
# reads an AWS profile and refuses an endpoint other than loopback.
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <stack-directory> <terraform arguments...>" >&2
  exit 64
fi

catalog_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_dir="$(cd "${catalog_dir}/../.." && pwd)"
stack_dir="$1"
shift

if [[ "$stack_dir" = /* ]]; then
  target_dir="$stack_dir"
else
  target_dir="${catalog_dir}/${stack_dir}"
fi

if [[ ! -d "$target_dir" || ! -f "$target_dir/main.tf" ]]; then
  echo "Local stack not found or incomplete: $target_dir" >&2
  exit 64
fi

# shellcheck source=/dev/null
source "${repository_dir}/tools/floci/env.sh"

# This workstation has a global Git URL rewrite from GitHub HTTPS to SSH.
# Terraform module downloads must stay on HTTPS so this catalog works without
# an SSH agent and never inherits a developer's Git identity configuration.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

case "${AWS_ENDPOINT_URL}" in
  http://localhost:4566|http://127.0.0.1:4566) ;;
  *)
    echo "Refusing Terraform: AWS_ENDPOINT_URL must be local Floci (got ${AWS_ENDPOINT_URL})." >&2
    exit 64
    ;;
esac

exec terraform -chdir="$target_dir" "$@"
