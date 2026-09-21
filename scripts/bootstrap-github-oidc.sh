#!/usr/bin/env bash
# Bootstrap GitHub OIDC in one AWS account from a short-lived IAM Identity
# Center session. This script never reads or writes long-lived credentials.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/bootstrap-github-oidc.sh \
    --profile <sso-profile> \
    --role-prefix <name-prefix> \
    [--region us-east-2] [--stack-name devops-aws-infra-github-oidc]

The target AWS account is determined by the supplied SSO profile. The script
uses this repository's immutable GitHub OIDC subject prefix by default. Pass
GITHUB_SUBJECT_PREFIX only when intentionally bootstrapping a fork or another
approved repository.
EOF
}

profile=""
region="us-east-2"
role_prefix=""
stack_name="devops-aws-infra-github-oidc"
# GitHub's standard OIDC `sub` uses the repository slug, not numeric GitHub
# IDs. The suffix is added by the CloudFormation template for pull requests or
# an approved deployment Environment.
subject_prefix="${GITHUB_SUBJECT_PREFIX:-repo:hatan4ik/devops-aws-infra}"

while (($# > 0)); do
  case "$1" in
    --profile) profile="${2:?missing profile value}"; shift 2 ;;
    --region) region="${2:?missing region value}"; shift 2 ;;
    --role-prefix) role_prefix="${2:?missing role-prefix value}"; shift 2 ;;
    --stack-name) stack_name="${2:?missing stack-name value}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ -z "$profile" || -z "$role_prefix" ]]; then
  usage >&2
  exit 64
fi

if [[ ! "$subject_prefix" =~ ^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  printf 'GitHubSubjectPrefix must use the standard repo:OWNER/REPO OIDC subject prefix.\n' >&2
  exit 64
fi

repo_root="$(git rev-parse --show-toplevel)"
template="$repo_root/bootstrap/github-oidc/template.yaml"

if [[ ! -f "$template" ]]; then
  printf 'expected bootstrap template is missing: %s\n' "$template" >&2
  exit 66
fi

caller_account="$(aws sts get-caller-identity --profile "$profile" --query Account --output text)"
printf 'Bootstrapping GitHub OIDC in AWS account %s, region %s, stack %s.\n' \
  "$caller_account" "$region" "$stack_name"

aws cloudformation validate-template \
  --profile "$profile" \
  --region "$region" \
  --template-body "file://$template" >/dev/null

aws cloudformation deploy \
  --profile "$profile" \
  --region "$region" \
  --stack-name "$stack_name" \
  --template-file "$template" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    "GitHubSubjectPrefix=$subject_prefix" \
    "RoleNamePrefix=$role_prefix" \
  --tags ManagedBy=devops-aws-infra Purpose=github-actions-oidc

aws cloudformation describe-stacks \
  --profile "$profile" \
  --region "$region" \
  --stack-name "$stack_name" \
  --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' \
  --output table
