#!/usr/bin/env bash
# Reconciles only the GitHub OIDC trust documents of legacy bootstrap roles.
# It never creates/deletes IAM resources or attaches/detaches permissions.
set -euo pipefail

profile=""
role_prefix=""
subject_prefix="${GITHUB_SUBJECT_PREFIX:-repo:hatan4ik/devops-aws-infra}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/reconcile-github-oidc-trust.sh \
    --profile <sso-profile> \
    --role-prefix <name-prefix>

Updates the assume-role trust policy of an existing legacy GitHub OIDC role
set to GitHub's standard repo:OWNER/REPO subjects. It creates no IAM provider,
role, policy, or AWS infrastructure resource and does not alter permissions.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --profile) profile="${2:?missing profile value}"; shift 2 ;;
    --role-prefix) role_prefix="${2:?missing role-prefix value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ -z "$profile" || -z "$role_prefix" ]]; then
  usage >&2
  exit 64
fi

if [[ ! "$subject_prefix" =~ ^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  printf 'GITHUB_SUBJECT_PREFIX must use the standard repo:OWNER/REPO OIDC subject prefix.\n' >&2
  exit 64
fi

command -v jq >/dev/null || { printf 'jq is required to construct the reviewed trust documents.\n' >&2; exit 69; }

account_id="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
provider_arn="arn:aws:iam::${account_id}:oidc-provider/token.actions.githubusercontent.com"
aws iam get-open-id-connect-provider \
  --profile "$profile" \
  --open-id-connect-provider-arn "$provider_arn" >/dev/null

trust_file="$(mktemp "${TMPDIR:-/tmp}/devops-aws-infra-oidc-trust.XXXXXX")"
trap 'rm -f -- "$trust_file"' EXIT

role_suffixes=(
  'plan:pull_request'
  'dev-apply:environment:dev'
  'staging-apply:environment:staging'
  'prod-apply:environment:prod'
  'drift:environment:dev'
  'landing-zone:environment:landing-zone'
)

for role_suffix in "${role_suffixes[@]}"; do
  role_name="${role_prefix}-${role_suffix%%:*}"
  suffix="${role_suffix#*:}"
  subject="${subject_prefix}:${suffix}"

  aws iam get-role --profile "$profile" --role-name "$role_name" --query 'Role.Arn' --output text >/dev/null

  jq -n \
    --arg provider_arn "$provider_arn" \
    --arg subject "$subject" \
    '{
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: {Federated: $provider_arn},
        Action: "sts:AssumeRoleWithWebIdentity",
        Condition: {
          StringEquals: {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub": $subject
          }
        }
      }]
    }' >"$trust_file"

  aws iam update-assume-role-policy \
    --profile "$profile" \
    --role-name "$role_name" \
    --policy-document "file://${trust_file}"

  printf 'Reconciled %s to %s.\n' "$role_name" "$subject"
done
