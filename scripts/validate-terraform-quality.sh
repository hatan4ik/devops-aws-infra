#!/usr/bin/env bash
# Credential-free validation for the GitOps source repository. It initializes
# every Terraform directory with -backend=false and never calls plan/apply.
set -euo pipefail

# Run from the repository root like verify-adr-boundary.sh so every relative
# path below holds regardless of the caller's working directory.
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

"$repository_root/scripts/verify-adr-boundary.sh"

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

shell_directories=()
for shell_directory in scripts tests/post_deploy; do
  if [[ -d "$shell_directory" ]]; then
    shell_directories+=("$shell_directory")
  fi
done

while IFS= read -r -d '' shell_file; do
  shellcheck "$shell_file"
done < <(find "${shell_directories[@]}" -type f -name '*.sh' -print0)

modules=()
while IFS= read -r directory; do
  modules+=("$directory")
done < <(find infra -type d -name .terraform -prune -o -type f -path '*/modules/*' -name versions.tf -exec dirname {} \; | sort)

roots=()
while IFS= read -r directory; do
  roots+=("$directory")
done < <(find infra -type d -name .terraform -prune -o -type f -path '*/roots/*' -name main.tf -exec dirname {} \; | sort)

# tflint --chdir does not load a parent .tflint.hcl, so pass the root config
# explicitly as an absolute path.
tflint_config="$repository_root/.tflint.hcl"

terraform fmt -check -recursive -no-color infra

# modules is empty while no child module lives under infra; the guard keeps the
# capability without tripping set -u on bash 3.2.
for directory in ${modules[@]+"${modules[@]}"}; do
  test_file="$directory/tests"
  if [[ ! -d "$test_file" ]] || ! compgen -G "$test_file/*.tftest.hcl" >/dev/null; then
    echo "module has no Terraform test file: $directory" >&2
    exit 1
  fi

  terraform -chdir="$directory" init -backend=false -input=false -lockfile=readonly -no-color

  # Terraform cannot standalone-validate a child module that requires caller
  # provider aliases. A mock-backed test is a stronger, configured plan for
  # that contract; ordinary modules receive both validate and test coverage.
  if grep -q 'configuration_aliases' "$directory/versions.tf"; then
    terraform -chdir="$directory" test -no-color
  else
    terraform -chdir="$directory" validate -no-color
    terraform -chdir="$directory" test -no-color
  fi

  tflint --chdir="$directory" --config="$tflint_config" --init
  tflint --chdir="$directory" --config="$tflint_config"
  printf 'PASS: module quality %s\n' "$directory"
done

for directory in ${roots[@]+"${roots[@]}"}; do
  terraform -chdir="$directory" init -backend=false -input=false -lockfile=readonly -no-color
  terraform -chdir="$directory" validate -no-color

  if [[ -d "$directory/tests" ]] && compgen -G "$directory/tests/*.tftest.hcl" >/dev/null; then
    terraform -chdir="$directory" test -no-color
  fi
  tflint --chdir="$directory" --config="$tflint_config" --init
  tflint --chdir="$directory" --config="$tflint_config"
  printf 'PASS: root quality %s\n' "$directory"
done
