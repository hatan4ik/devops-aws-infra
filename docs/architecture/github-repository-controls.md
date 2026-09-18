# GitHub repository controls

**Status:** The repository now enforces full-SHA action pinning. The remaining controls in this document are stakeholder-approved design requirements, not configured remote controls; they require the target organization, owners, environments, and AWS identity inputs.

GitHub rulesets will be preferred where the selected organization plan supports them, because their rules can layer and the most restrictive applicable rule wins. The preflight must confirm the plan and private-repository feature availability; otherwise an equivalent protected-branch configuration is required. GitHub documents ruleset layering, required signed commits, reviewer requirements, and source-bound status checks in its [ruleset reference](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).

## Mandatory `main` ruleset / branch protection profile

Apply this profile to every proposed repository, with no administrator bypass except an audited, time-bound emergency process.

| Control | Planned setting | Reason |
|---|---|---|
| Merge path | Pull requests only; direct pushes prohibited. | Every infrastructure and workflow change receives review and checks. |
| Reviews | Two approvals; matching CODEOWNER approval; dismiss stale approvals; require approval from someone other than the last code pusher. | Implements A-17 and separation of duties. |
| Conversations | All review conversations resolved before merge. | Open risk or correctness feedback cannot be silently merged. |
| Checks | Required, expected from the designated GitHub App, and current with `main`. | A same-named check from an untrusted source cannot satisfy a protection. |
| History | Linear history; force push and branch deletion prohibited. | Preserves reviewable, auditable provenance. |
| Commit identity | Verified signed commits required. | Binds merged history to a verified signer. |
| Bypass | No routine bypass actors; any emergency bypass is separately logged, reviewed, and followed by an incident/change record. | Prevents administrators from silently defeating the control. |

GitHub supports required pull-request review counts, CODEOWNER review, stale-review dismissal, status checks, signed commits, restrictions on force push/deletion, and no-bypass controls. The exact UI/API configuration must be captured as post-change evidence; the proposed control is not deemed implemented merely because a workflow file exists. See GitHub's [protected-branch settings](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches).

## Required checks by repository type

Check contexts are defined by the local Phase 6 pipeline source and must be bound to the ruleset only after each context has run from the approved GitHub App.

| Repository type | Required checks |
|---|---|
| Terraform module | `terraform_fmt`, `terraform_validate`, `tflint`, `security_scan`, `terraform_docs`, `terraform_test`, `plan_policy`, `cost_diff` |
| Terraform live root | `terraform_fmt`, `terraform_validate`, `tflint`, `security_scan`, `terraform_docs`, `terraform_test`, `plan_policy`, `cost_diff` |
| Workflow repository | `workflow_lint`, `action_pin_policy`, `security_scan`, `reusable_workflow_test` |
| Documentation repository | `markdown_lint`, `link_check`, `adr_traceability` |

`security_scan` is the Phase 6 Trivy/Checkov gate: it fails on HIGH or CRITICAL findings unless an approved, expiring, justified suppression is present. A plan is a review artifact, not an authorization to apply. Required GitHub checks prevent merge only when they pass; the control must avoid skip conditions that leave an expected check absent. See GitHub's [status-check behavior](https://docs.github.com/en/pull-requests/reference/status-checks).

## CODEOWNERS and reviewer boundary

Actual GitHub team slugs are not known and will not be invented. The following is the required ownership shape, to be populated during remote preflight:

```text
*                         @<org>/platform-owners
/docs/                    @<org>/platform-owners @<org>/security-owners
/modules/network/         @<org>/network-owners @<org>/platform-owners
/modules/identity/        @<org>/identity-owners @<org>/security-owners
/modules/security/        @<org>/security-owners @<org>/platform-owners
/roots/network/           @<org>/network-owners @<org>/security-owners
/roots/security/          @<org>/security-owners
/roots/identity/          @<org>/identity-owners @<org>/security-owners
/.github/                 @<org>/platform-owners @<org>/security-owners
```

The required CODEOWNER approval ensures an owner approves touched paths, but GitHub allows one of multiple listed owners to satisfy that requirement. The independent two-approval rule therefore remains mandatory; the review process must ensure required role diversity for changes affecting security, network, identity, OIDC, state, or production roots. Any change that weakens a ruleset, CODEOWNERS, workflow credential boundary, or required check is a security-sensitive change and needs Security Engineer and Platform/DevOps Lead approval.

## Tags, releases, and supply-chain controls

Module repositories protect the `v*` tag namespace: tags are semantic versions, created only by the approved release workflow after the module check profile passes. Tags are signed, immutable, and accompanied by release notes, compatibility statement, provider/Terraform version constraints, and migration notes for a breaking change. Root and documentation repositories do not publish Terraform modules.

All third-party GitHub Actions will be pinned to full commit SHAs, reviewed by action-pin policy, and upgraded through a pull request. Reusable workflows are called by immutable commit SHA from `<org>-terraform-pipelines`; a mutable branch ref is prohibited. Dependency updates, generated docs, and release automation remain subject to the same PR protections.

## AWS access from GitHub Actions

GitHub Actions obtains AWS credentials only through OIDC and scoped IAM roles; repository secrets must not contain long-lived AWS keys. GitHub's AWS guidance calls for `https://token.actions.githubusercontent.com`, `sts.amazonaws.com`, and evaluation of the OIDC `sub` claim in the AWS trust policy. See [Configuring OIDC in AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws).

Planned trust boundaries:

| Role type | Allowed token subject | AWS scope |
|---|---|---|
| Pull-request plan | Exact root repository and a protected plan environment/ref available in GitHub's standard OIDC `sub` claim; read-only plan data and encrypted state read as strictly necessary. | No apply permission. Remote preflight must prove callers cannot substitute a higher-privilege role. |
| Dev deploy | Exact root repository and protected `main` or approved `dev` environment. | One dev account/Region/environment role. |
| Staging deploy | Exact root repository and protected `staging` environment. | One staging account/Region/environment role after human gate. |
| Production deploy | Exact root repository and protected `production` environment. | One production account/Region/environment role after human gate. |
| Module release | Exact module repository and protected semantic-version tag/release workflow. | GitHub release/package permissions only; no AWS deployment role. |

Each workflow requests only the permissions it needs, including `id-token: write` only on jobs that actually exchange an OIDC token. GitHub's OIDC documentation recommends explicit trust conditions and environment protection rules; AWS trust policies must bind `aud` and `sub` to the exact repository/ref or environment. Because AWS does not support GitHub OIDC custom claims, the Phase 6 trust model must use supported standard claims rather than depend on organization custom properties.

## Remote-change preflight and evidence

Before applying any GitHub control, the repository administrator records: organization and repository IDs, visibility, default branch, ruleset/rule configuration, team slugs, CODEOWNERS resolution, exact required-check source, tag-protection result, Actions permission defaults, environment reviewers/branch restrictions, and the OIDC trust-policy subjects. A test pull request must prove that direct push, unsigned commit, missing code-owner review, stale review, failing check, non-current branch, and unauthorized OIDC subject are all rejected. The test must not call Terraform apply.
