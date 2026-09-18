# Phase 4 repository and module strategy

**Status:** Stakeholder-approved local Phase 4 design. No GitHub repository, remote, branch rule, tag, workflow, or AWS resource has been created or changed.

## Naming contract

Names are lowercase, hyphenated, and registry-compatible. `<org>` is intentionally unresolved until the GitHub organization owner confirms it (assumption A-16).

| Kind | Required pattern | Use |
|---|---|---|
| Reusable Terraform module | `terraform-aws-<component>` | A stable, independently versioned contract used by more than one production root or with a separate lifecycle. |
| Live platform configuration | `<org>-aws-platform-<layer>` | Composition and deployment roots for an account, Region, and environment. |
| Workload configuration | `<org>-aws-platform-workload-<app>` | The live composition for one application, created after its app slug and owners are known. |
| Documentation | `<org>-aws-platform-docs` | Architecture, ADRs, runbooks, source references, and traceability. |
| Reusable workflows | `<org>-terraform-pipelines` | Pinned, reviewed GitHub Actions reusable workflows. |

## Proposed final repository set

The following is a target inventory, not a command to create it. `terraform-aws-*` names omit `<org>` so consumers use consistent Terraform registry-style source names; organization ownership still scopes the remote repository.

| Repository | Purpose | Lifecycle decision |
|---|---|---|
| `terraform-aws-vpc-workload` | Private workload VPC, subnet, endpoint, flow-log, and encryption boundary contract. | Independent module repository. |
| `terraform-aws-tgw-hub` | Regional transit-gateway hub, RAM sharing, attachment, and route-segmentation contract. | Independent module repository. |
| `terraform-aws-cognito-userpool` | Cognito user-pool security, custom-domain, KMS, and multi-Region-replication-ready contract. | Independent module repository. |
| `<org>-aws-platform-org` | Organizations, Control Tower/AFT configuration, account vending requests, and SCP composition. | Live root repository. |
| `<org>-aws-platform-foundation` | Shared-services state-backend bootstrap and organization-wide CI identity prerequisites. | Live root repository; its bootstrap procedure is isolated to avoid state-backend circularity. |
| `<org>-aws-platform-network` | IPAM, regional TGWs, Route 53 Resolver, endpoints, hybrid VPN/BGP, and network account roots. | Live root repository. |
| `<org>-aws-platform-security` | Log Archive, detective controls, delegated-security configuration, KMS, and security account roots. | Live root repository. |
| `<org>-aws-platform-identity` | IAM Identity Center, permission sets, and organization identity configuration. | Live root repository. |
| `<org>-aws-platform-workload-<app>` | One application's dev, staging, and prod regional composition, including its use of the published modules. | One repository per application once an app identifier and owning team are approved. |
| `<org>-aws-platform-docs` | This design package, ADRs, runbooks, reference digests, and requirement traceability. | Documentation repository. The current workspace is only a candidate source for it. |
| `<org>-terraform-pipelines` | Reusable CI/CD workflows and pinned action policy shared by Terraform repositories. | Workflow repository. |

No other repository is proposed for the initial platform. In particular, security baselines, VPN onboarding, observability, Route 53 Resolver, account vending, Fargate composition, and DynamoDB tables begin as repository-local modules because they have one live owner and need coordinated root changes. They graduate only under the A-18 extraction rule, through a new ADR and migration plan.

## Why the split is deliberately small

The SES material separates network/TGW/VPN concerns from workloads, while the reviewed Modernisation Platform reference keeps internal modules internal until mature enough for their own repository. This plan adopts that boundary: the VPC, TGW, and Cognito interfaces have clear consumers and release compatibility needs; the rest are platform composition, not public abstractions.

This prevents a central repository from coupling every plan, while avoiding a repository-per-resource estate. Roots compose only published module versions or repository-local composition modules; reusable modules accept identifiers, ARNs, CIDRs, and typed inputs rather than reading another team's state.

## Repository layout and promotion model

Every live repository has the same environment shape. A root represents exactly one `(account, Region, environment)` tuple and contains only provider, backend, variable, and module-call composition; it does not declare bare AWS resources.

```text
<org>-aws-platform-network/
  modules/                       # internal composition only; not a registry contract
    hybrid-vpn/
    route53-resolver/
    tgw-attachment/
  roots/
    network/us-east-1/shared/
      backend.tf
      providers.tf
      main.tf
      variables.tf
      terraform.tfvars
  .github/workflows/
  CODEOWNERS
```

```text
terraform-aws-vpc-workload/
  main.tf
  variables.tf
  outputs.tf
  locals.tf
  versions.tf
  examples/
  tests/
  README.md                       # rendered and checked with terraform-docs
  .github/workflows/
  CODEOWNERS
```

Dev, staging, and prod use identical directory and module-call structure. Promotion reuses the same revision with different reviewed inputs; secrets never appear in `terraform.tfvars` or state where avoidable. The foundation bootstrap root is the explicit exception: it begins from an approved local/bootstrap procedure and migrates to the isolated S3/DynamoDB backend only after that backend exists.

## Versioning, dependencies, and module graduation

- Every module repository uses semantic version tags (`vMAJOR.MINOR.PATCH`), signed and protected against deletion or overwrite. Breaking interface changes require a new major version, migration instructions, and a consumer compatibility test.
- Root repositories pin module references to immutable release tags (and, after Phase 6, pin third-party actions to immutable commit SHAs). Floating module branches, `latest`, and mutable action tags are prohibited.
- A new reusable module requires evidence of the A-18 threshold, a single-responsibility README, typed input/output contract, examples, `terraform test`, semantic-version plan, owners, and an ADR showing why a local module is no longer sufficient.
- A module is deprecated with a documented successor, migration guide, supported-version window, and consumer inventory. It is not deleted while supported roots still consume it.

## Reference and source-control boundary

The shallow clones in `reference/github/` are review evidence only. They must not be copied into a platform repository, treated as dependencies, or included in a future initial push. Their license, commit, and provenance stay recorded in [the GitHub reference inventory](../reference/github-repos.md). The source documents in this workspace are candidates for `<org>-aws-platform-docs`; creating that remote, initializing its policy, or pushing its contents requires a separate remote-change approval.

## Creation sequence after remote-change approval

1. Confirm `<org>`, GitHub plan capabilities, team slugs, repository visibility, license policy, and the first workload app slug.
2. Create the documentation and pipelines repositories, then the live root repositories, with no AWS deployment credentials or secrets committed.
3. Create only the three module repositories above; add skeletons and test contracts in Phase 5.
4. Apply the planned rulesets, CODEOWNERS, environments, release/tag controls, and OIDC trust constraints described in [GitHub repository controls](github-repository-controls.md).
5. Verify the controls through GitHub API/UI evidence before any pipeline receives AWS role access.

The sequence creates GitHub state and is therefore outside this approved design phase.
