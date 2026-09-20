#!/usr/bin/env bash
# Credential-free validation for the GitOps source repository. It initializes
# every Terraform directory with -backend=false and never calls plan/apply.
set -euo pipefail

"$(dirname -- "${BASH_SOURCE[0]}")/verify-adr-boundary.sh"
bash -n scripts/verify-legacy-state-backend-adoption.sh

for required_command in terraform tflint; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "required command is not available: $required_command" >&2
    exit 69
  }
done

command -v shellcheck >/dev/null 2>&1 || {
  echo "required command is not available: shellcheck" >&2
  exit 69
}

while IFS= read -r -d '' shell_file; do
  shellcheck "$shell_file"
done < <(find scripts automation -type f -name '*.sh' -print0)

modules=()
while IFS= read -r directory; do
  modules+=("$directory")
done < <(find terraform/modules -name versions.tf -exec dirname {} \; | sort)

roots=()
while IFS= read -r directory; do
  roots+=("$directory")
done < <(find terraform/roots -name main.tf -exec dirname {} \; | sort)

terraform fmt -check -recursive -no-color terraform

for directory in "${modules[@]}"; do
  test_file="$directory/tests"
  if [[ ! -d "$test_file" ]] || ! compgen -G "$test_file/*.tftest.hcl" >/dev/null; then
    echo "module has no Terraform test file: $directory" >&2
    exit 1
  fi

  terraform -chdir="$directory" init -backend=false -input=false -lockfile=readonly -no-color

  # Terraform cannot standalone-validate a child module that requires caller
  # provider aliases. A mock-backed test is a stronger, configured plan for
  # that contract; ordinary modules receive both validate and test coverage.
  if rg -q 'configuration_aliases' "$directory/versions.tf"; then
    terraform -chdir="$directory" test -no-color
  else
    terraform -chdir="$directory" validate -no-color
    terraform -chdir="$directory" test -no-color
  fi

  tflint --chdir="$directory" --init
  tflint --chdir="$directory"
  printf 'PASS: module quality %s\n' "$directory"
done

for directory in "${roots[@]}"; do
  terraform -chdir="$directory" init -backend=false -input=false -lockfile=readonly -no-color
  terraform -chdir="$directory" validate -no-color

  if [[ -d "$directory/tests" ]] && compgen -G "$directory/tests/*.tftest.hcl" >/dev/null; then
    terraform -chdir="$directory" test -no-color
  fi
  tflint --chdir="$directory" --init
  tflint --chdir="$directory"
  printf 'PASS: root quality %s\n' "$directory"
done
