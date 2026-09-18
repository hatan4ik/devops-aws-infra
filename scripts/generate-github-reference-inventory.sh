#!/usr/bin/env bash
# shellcheck disable=SC2016 # Markdown backticks are deliberately literal output.
# Regenerates the read-only GitHub reference snapshot used by Phase 1.
set -euo pipefail

account="${1:?usage: $0 <github-account>}"
output="docs/reference/github-repos.md"
generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "$output")"

{
  printf '%s\n\n' '# GitHub AWS reference inventory'
  printf 'Snapshot generated from `%s` at `%s` using the authenticated GitHub CLI. A repository is included when its name, description, or topics contains `aws` (case-insensitive).\n\n' "$account" "$generated_at"
  printf '%s\n' '| Repository | Relationship | Stars | Last updated | Description | URL |'
  printf '%s\n' '|---|---:|---:|---|---|---|'

  gh repo list "$account" --limit 1000 --json name,description,repositoryTopics,url,stargazerCount,updatedAt \
    | jq -r '
        def matches_aws:
          ([.name, (.description // "")] + [(.repositoryTopics // [])[]?.name])
          | join(" ") | test("aws"; "i");
        map(select(matches_aws))
        | sort_by(.name | ascii_downcase)
        | .[]
        | [
            ("`'"$account"'/" + .name + "`"),
            "owned",
            (.stargazerCount | tostring),
            .updatedAt,
            ((.description // "") | gsub("[\\r\\n|]+"; " ")),
            ("[link](" + .url + ")")
          ]
        | "| " + join(" | ") + " |"'

  gh api user/starred --paginate --slurp \
    | jq -r '
        def matches_aws:
          ([.name, (.description // "")] + [(.topics // [])[]?])
          | join(" ") | test("aws"; "i");
        add | map(select(matches_aws))
        | sort_by((.owner.login + "/" + .name) | ascii_downcase)
        | .[]
        | [
            ("`" + .full_name + "`"),
            "starred",
            (.stargazers_count | tostring),
            .updated_at,
            ((.description // "") | gsub("[\\r\\n|]+"; " ")),
            ("[link](" + .html_url + ")")
          ]
        | "| " + join(" | ") + " |"'

  cat <<'EOF'

## Candidate review

The snapshot contains 134 matching repositories: 11 owned and 123 starred. The eight shallow clones below were selected by direct relevance to landing-zone account vending, Terraform module architecture, segmented Transit Gateway networking, VPN/BGP, private service connectivity, or application delivery. They are reference material only; their code and defaults are not inherited by this platform.

| Reference | Pinned revision | What to adopt | What not to adopt without a later ADR | License |
|---|---|---|---|---|
| `aws-ia/terraform-aws-control_tower_account_factory` | `c5d871757803f73e0ffa144f433e6038b59f366b` | GitOps account-request workflow, separate AFT management account, account customizations, generated Terraform documentation, and explicit provider/version constraints. | Direct reuse of its root-level providers, AdministratorAccess bootstrap requirement, HCP Terraform integration, or its network/state defaults. The future account-vending decision must compare Control Tower + AFT with custom Organizations + SCPs first. | Apache-2.0 |
| `ministryofjustice/modernisation-platform` | `96bc811a9858196ef382174b94c75f31280fe20c` | Central environment definitions, CIDR allocation, policy directory, ADR discipline, and keeping modules in a monorepo until they have an independent lifecycle. | Its organization-specific accounts, operational policies, pipeline behavior, and security controls. Those are implementation-specific and require a separate design decision. | MIT |
| `terraform-aws-modules/terraform-aws-transit-gateway` | `7973ea0890176868b62bb60a694768cec19daf9a` | Stable map keys for attachments, explicit route/association resources, and a multi-account example. | Its permissive attachment input (`any`) and any default association/propagation behavior. Our TGWs will disable both defaults and create explicit segmented route tables. | Apache-2.0 |
| `plus3it/terraform-aws-tardigrade-transit-gateway` | `f1355e09ebce5aced4510a59f6ed5bd349513470` | Separate cross-account VPC attachment acceptance and cross-region peering workflows using provider aliases. | Its defaults for association/propagation or test profiles. Internal modules must satisfy this brief's no-provider-block, typed-variable, and OIDC-only rules. | Apache-2.0 |
| `terraform-aws-modules/terraform-aws-vpn-gateway` | `424403434002074072426d659949ed23771fd7a0` | The documented VPN-to-TGW topology, BGP as the dynamic-routing default, dual-tunnel awareness, and examples for explicit tunnel CIDRs. | Any configuration that supplies tunnel preshared keys in Terraform inputs/state, or an architecture centered on a VPC VPN gateway rather than the regional TGW hub. | Apache-2.0 |
| `aws-samples/private-saas-with-aws-privatelink` | `4115bc0d2382d18ebb26811da5e7300902cf0773` | The NLB/ALB and NLB/API Gateway PrivateLink topology distinctions, architecture diagram, and template tests. | Its lab root configurations and provider blocks. PrivateLink is for AWS service access and private producer/consumer flows, not a substitute for TGW network segmentation. | MIT-0 |
| `aws-samples/aws-modern-application-workshop` | `3ccc1376c2df16cd87c1ff989f9c8d2612f80667` | The AWS-native application-delivery reference (containers, Fargate, CI/CD) for evaluating the lowest-operations compute option. | Workshop infrastructure or deployment defaults as a multi-account platform baseline. It is application training material, not a landing-zone implementation. | Apache-2.0 |
| `hatan4ik/ovp-aws-infra` | `a4d6f4618b55f6319c66fe3886955482a756bfa8` | Existing AWS topology diagrams as historical visual input only. | Any code reuse: the checkout has diagrams/scripts rather than a maintained Terraform module structure and does not declare a license. | No license found |

## Reproduce the snapshot

Run `bash scripts/generate-github-reference-inventory.sh hatan4ik`. The script performs GitHub read-only queries and updates this timestamped inventory. Clones are shallow checkouts under `reference/github/` and must remain unmodified.
EOF
} > "$output"

printf 'Wrote %s\n' "$output"
