# Engineering pillars review — 2026-09-18

**Audience:** the platform owner and the five-reviewer design board defined in the brief.
**Reviewed:** a point-in-time copy of the working tree taken at 16:53:56 IDT on 2026-09-18, commit `1b71014`. The copy was made because a second agent session was committing to this repository during the review. Paths and line numbers refer to that copy; where the live tree has since moved, it is called out.
**Method:** one independent reviewer per pillar (SOLID, Clean Code, Pragmatic Programming, Systems Engineering, Type-System Thinking), each restricted to read-only inspection and required to quote file evidence, plus the repository's own quality gate (`scripts/validate-terraform-quality.sh`) and Checkov executed on the copy. Every finding below was re-checked against the files before inclusion. No file in the repository was modified by this review other than the creation of this document.
**Path shorthand:** `vpc-workload/`, `tgw-hub/`, and `cognito/` (or `cognito-userpool/`) abbreviate `terraform/modules/terraform-aws-<name>/`; `state-backend/`, `workload-regional/`, `network-regional/`, and `tgw-vpc-attachment/` are under `terraform/modules/internal/`; `*.tftest.hcl` files are in each module's `tests/` directory; `foundation/.../` is `terraform/roots/foundation/region-a/shared/`; `automation/.../` is `automation/terraform-pipelines/`. Files named only in section 5 and 6 are proposals and do not exist yet.

## 1. Verdict

| Pillar | Verdict | Blockers | Headline |
|---|---|---|---|
| 1 SOLID | Not met | 1 | The two internal wrapper modules are roots in disguise, and the registry modules' input schemas are hand-copied into eight files. |
| 2 Clean Code | Not met | 1 | About 70% of the root layer is copy-paste; names are assembled inline; no lint or docs configuration exists; the only ADR link is now ambiguous. |
| 3 Pragmatic | Not met | 4 | No tracer-bullet slice; no `moved`, `prevent_destroy`, or versioned module source anywhere; account, Region, and VPN onboarding exist only as prose; no value class has a single source. |
| 4 Systems Engineering | Not met | 5 | Two contradictory "Accepted" ADR series; the assumptions register was overwritten; no traceability matrix, interface table, failure-mode table, or quota/headroom table. |
| 5 Type-System | Not met | 1 | Lock files are gitignored and module provider constraints are open-ended, so an incompatible upgrade does not fail at init; boundary invariants exist as prose, not code. |

What is genuinely strong and should be preserved:

- Dependency inversion is clean at the resource layer: no `data` blocks, no `terraform_remote_state`, no provider blocks in modules, no account IDs or Region literals in code. Roots are module calls only and pin the provider to `var.aws_account_id`.
- Types are disciplined: zero `type = any`, 87 of 87 variables carry `nullable = false` and a description, 46 validation blocks, closed enums for `feature_plan`, `mfa_configuration`, `route_domain`, `identity.mode`, and `environment`, stable string `for_each` keys everywhere, no `count`, no `[0]` indexing.
- The identity variant (`identity.mode` plus `optional(object)` with a cross-field validation) is the pattern the brief asks for, and a test proves the illegal combination fails.
- The quality gate passes on the copy: `fmt`, `init`, `validate`, `tflint`, and 13 mocked `terraform test` runs across 7 modules; Checkov reports 43 passed, 0 failed. All third-party actions are SHA-pinned and a script enforces it. Drift never remediates, and that property is asserted in CI.
- The older ADR series (0001-control-tower-account-vending through 0013) meets the operating standard: context, three options, named dissent with reasons, decision, consequences.

## 2. Precondition: the repository is being rewritten concurrently

This is not a pillar finding but it blocks every pillar finding. A second agent session was committing to this repository during the review and is still active. Its commit `bfe6b4f` ("Auto comit message", 16:52:06) did the following:

- Added a second ADR series (`0001-account-structure.md` through `0008-observability.md`, later `0009-repository-strategy.md`) that reuses existing numbers and decides the same questions differently, with both files marked Accepted. Nine numbers now have two files each.
- Replaced `docs/ASSUMPTIONS.md` (the 34-line `A-01` to `A-19` register with the `10.128.0.0/9` CIDR placeholder) with a 26-line prose file carrying different numbers. Thirteen documents still cite `A-xx` identifiers that no longer resolve. The original is recoverable with `git show 91190e9:docs/ASSUMPTIONS.md`.
- Committed the eight `reference/github/*` clones as gitlinks (mode 160000) without a `.gitmodules` file, so a fresh clone gets eight empty directories.
- Removed five lines from the root `.gitignore`.

Later commits from the same session (`8eef6fd`, `8d5395e`, `35e1aa5`) rewrote the root workflows and, at the time of writing, have uncommitted edits to the `state-backend` module and the foundation root.

Required first steps, in order:

1. Serialize the sessions. One writer at a time on this tree.
2. Decide which ADR series survives. Mark every file in the other series `Status: Superseded by <path>`, keep exactly one file per number, and keep exactly one decision index (`docs/architecture/README.md:75` and `docs/architecture/phase-3-summary.md:7` currently point at different files for the same decision). Replace the `file:///Users/...` links in `phase-3-summary.md` with relative links.
3. Restore the assumptions register from `91190e9`. If the new numbers (5,000 auth RPS, 25,000 API RPS, p99 200 ms, RTO 15 min) are intended, record them as an ADR amendment and update the cost model, Cognito quota plan, SLO table, and failover runbook that were built against 300 RPS per Region, 10,000 RPS, p99 250 ms, and RTO 60 min.
4. Run `git rm --cached -r reference/github` and restore the `.gitignore` lines so the clones stay untracked.

## 3. Machine evidence on the reviewed copy

| Check | Result |
|---|---|
| `terraform fmt -check -recursive` | clean |
| `init -backend=false`, `validate`, `tflint`, `terraform test` for 7 modules | all pass, 13 runs |
| `init`, `validate`, `tflint` for 9 roots | all pass |
| Checkov, `terraform` framework | 43 passed, 0 failed, 0 skipped |
| `type = any` / `map(any)` / `list(any)` | 0 |
| Variables / with `nullable = false` / with `description` | 87 / 87 / 87 |
| `validation` blocks / `precondition` / `postcondition` / `check` / `moved` | 46 / 1 / 0 / 0 / 0 |
| `prevent_destroy` / `create_before_destroy` | 0 / 0 |
| `data` blocks / `terraform_remote_state` / `count` / `[0]` in outputs | 0 / 0 / 0 / 0 |
| Provider blocks inside modules | 0 |
| Account IDs, Region names, CIDRs hardcoded in `.tf` | 0 |
| Files over 300 lines | 0 (largest is 154) |
| `.terraform.lock.hcl` tracked by git | 0 of 16 (`terraform/.gitignore:2`) |
| `terraform.tfvars` tracked by git | 0 of 9 (`.gitignore:16`) although `phase-5-traceability.md:13` says they are committed by design |
| Root `README.md` files | 0 of 9 |
| `.tflint.hcl`, `.terraform-docs.yml`, `.pre-commit-config.yaml`, `.editorconfig`, PR template, `docs/traceability.md`, ADR template, `CHANGELOG.md`, `examples/` | all absent |
| Provider constraint | `>= 6.35.0` in 7 modules (open-ended); `~> 6.0` in 9 roots |
| Terraform CLI version literal `1.7.5` | 7 files |

## 4. Findings

Severity: **B** = blocker (the pillar owner would not approve), **M** = major, **m** = minor. Pillars that raised the same finding are listed in brackets.

### Cross-cutting blockers

**B1. The ADR corpus is forked** [3, 4]. Nine numbers, two Accepted files each, opposite decisions on landing zone (`0001-control-tower-account-vending.md:30` vs `0001-account-structure.md:15`), identity replication (`0006-identity-and-authorization.md:30` vs `0004-identity-provider.md:17`), dynamic ingress (`0004-edge-ingress-and-egress.md:30` Global Accelerator vs `0006-edge-ingress.md:25` CloudFront only), egress (`0004-edge-ingress-and-egress.md:32` no Internet route vs `0005-egress-inspection.md:17` NAT per AZ), observability account (`0009-observability-and-sre.md:30` vs `0008-observability.md:17`), failover semantics (`platform.md:47` incident-commander decision vs `0002-multi-region-strategy.md:20` "near-zero RTO"), and auth capacity (300 RPS per Region vs 5,000 RPS). Two of the newer ADRs fail the "two rejected alternatives" rule (`0001-account-structure.md:12` lists a deprecated option as its third; `0007-fine-grained-auth.md:14-16` gives no rejection reasons). Until this is resolved, "traceable to an ADR" is unfalsifiable. See section 2.

**B2. The assumptions register was overwritten and the numbers now contradict the design** [3, 4]. `docs/ASSUMPTIONS.md` defines no `A-xx` identifiers; `phase-3-traceability.md:5`, `network-security.md:5`, ADRs, and runbooks cite `A-01` to `A-19` and the CIDR placeholder. `ASSUMPTIONS.md:6` says 5,000 auth RPS; `0006-identity-and-authorization.md:30` plans 300 per Region; `cost-estimate.md:12` buys toward 300; `phase-3-summary.md:26` admits defaults cannot support 5,000. See section 2.

**B3. Versions are not types** [5, 3]. `terraform/.gitignore:2` ignores `.terraform.lock.hcl`, so none of the 16 lock files is tracked and CI resolves providers fresh on every run. All 7 module `versions.tf:7` use `>= 6.35.0`, which a future provider 7.0.0 satisfies; failure would surface at plan or apply, not init. No `init` in `scripts/validate-terraform-quality.sh:38` or the four reusable workflows passes `-lockfile=readonly`. Roots use `~> 6.0`, a second flavour of the same constraint. Local lock files are already inconsistent (3 carry one hash, 13 carry sixteen), confirming they are uncontrolled.

**B4. No rollback path on the most destructive resources** [3]. Zero `moved`, `prevent_destroy`, `create_before_destroy`, or `import` blocks in `terraform/`. `state-backend/main.tf:1,22,129` (KMS key, state bucket, lock table) and `cognito-userpool/main.tf:14` (`deletion_protection` driven by a bool tfvar) have no lifecycle protection; flipping `object_lock.enabled` forces state-bucket replacement. `foundation/.../terraform.tfvars.example:10,12` shows `noncurrent_version_expiration_in_days = 0` and Object Lock disabled for all tiers, and no runbook describes state restore. Every module source is an unversioned relative path while `repository-strategy.md:83` promises immutable release tags; no `CHANGELOG.md` or `examples/` exists although `phase-5-traceability.md:14` claims they are implemented.

**B5. No tracer bullet** [3]. The design and the nine roots go straight to two Regions and three environments. The only mention of a thin slice is `0007-fine-grained-auth.md:23` in the forked series, and the end-to-end auth request is delegated away in `tests/post_deploy/auth-api-synthetic-contract.md:24`.

**B6. Repeated operations are prose, not code** [3]. `runbooks/account-vending.md:16` submits an AFT request through a root that does not exist (no `aws_organizations_*`, `aws_controltower_*`, or AFT module). `runbooks/adding-region.md:18` applies IPAM, Resolver, VPN, and peering resources that no module creates. `runbooks/hybrid-vpn-bgp-onboarding.md:16` likewise. The drift caller `.github/workflows/terraform-drift.yml:20-22` is `exit 1`. Adding a Region today is `cp -r region-a region-b`.

**B7. The root layer is copy-paste and the boundary type is declared eight times** [1, 2, 3, 5]. `providers.tf` and `versions.tf` are byte-identical across all 9 roots; `main.tf`, `locals.tf`, `outputs.tf` are identical across the 6 workload roots; `variables.tf` differs by at most 4 of 86 lines (the environment guard and two description strings). The ~50-line `vpc`/`identity` object type lives in the two registry modules, again in `internal/workload-regional/variables.tf:9-62`, and again in all 6 workload roots (`variables.tf:24-79`). The copies have already drifted: the wrapper requires `interface_endpoints` and `gateway_endpoints` that the leaf defaults to `{}` (`vpc-workload/variables.tf:69,84`). Roughly 771 of 1,102 root lines exist only as copies. The variable descriptions themselves say `region-a is only a directory placeholder`.

**B8. No traceability matrix** [4]. `docs/traceability.md` does not exist. The per-phase tables have `Requirement | Evidence | Status` columns only; no code or test column. Requirements 3.2 (Organizations, SCPs, vending), 3.5 (security baseline), 3.6 (observability), and most of 3.4 (compute, data, edge, secrets) map to prose only; no `aws_organizations_*`, `aws_cloudtrail`, `aws_guardduty_*`, `aws_securityhub_*`, `aws_config_*`, `aws_ecs_*`, `aws_lb*`, `aws_cloudfront_*`, `aws_globalaccelerator_*`, `aws_wafv2_*`, or `aws_oam_*` resource exists.

**B9. Capacity and quotas are not design inputs** [4]. The assumed auth peak is about eight times the planned purchased Cognito capacity (`cost-estimate.md:12`: 2 x 300 RPS) and no document says how the gap closes. The word "headroom" appears nowhere under `docs/`. TGW attachment and route limits, VPN tunnel throughput and ECMP aggregate, IPAM pool limits, and interface-endpoint limits are not tabulated (`cost-estimate.md:51` mentions 1.25 Gbps only as a price cell).

**B10. No system boundary or interface inventory** [4]. Nothing enumerates on-prem BGP, GitHub OIDC, the Cognito custom domain and JWKS, AWS service endpoints, email/SMS senders, Infracost, or third-party APIs with owner, protocol, encryption, and failure mode. `network-security.md:67` gives protocol only; `external-verification.md:5` is a verification list, not an interface table.

### Pillar 1: SOLID

- **M1. Wrappers are roots in disguise.** `internal/workload-regional` composes networking and identity (`README.md:3` needs "and") behind a `mode == "primary"` string branch (`main.tf:16`) and owns no resources; `internal/network-regional` is a 1:1 pass-through to `terraform-aws-tgw-hub` with zero resources and a weaker input surface (`variables.tf:1-5` has no `name` validation while the leaf validates). Composition belongs in roots.
- **M2. `state-backend` is over-scoped and closed.** It owns a KMS key set, S3 storage, and DynamoDB locking across three tiers (`README.md:3`), and `variables.tf:27` hardcodes `length(var.state_tiers) == 3` with exactly `dev`, `staging`, `prod`. Adding a tier means editing the module. The foundation root's `state_backend` input (`variables.tf:34-53`) mixes storage, encryption, and access concerns in one blob.
- **M3. `vpc-workload` forces flow-log inputs.** The log group, IAM role, policy, and flow log (`main.tf:110-140`) are unconditional and `flow_log_kms_key_arn` / `flow_log_retention_in_days` are mandatory; a caller shipping flow logs centrally cannot use the module. `README.md:3` lists six sub-features joined by "and".
- **M4. `tgw-vpc-attachment` has no consumer.** No root or module sources it (only `validate-terraform-quality.sh:19` and a traceability row mention it); its `outputs.tf:2` describes an acceptance root that does not exist.
- **m.** Route-domain enum duplicated in `tgw-hub/locals.tf:3` and `tgw-vpc-attachment/variables.tf:46`. Cognito hardcodes `["COGNITO"]`, `["code"]`, `["email"]`, and the auth-flow list (`main.tf:18-19,92,100-101`) as constants rather than defaults. `repository-strategy.md:24-25` promises tgw-hub attachment/route inputs and a Cognito custom-domain/KMS input that the modules do not expose.

### Pillar 2: Clean Code

- **M5. Naming is assembled inline, not computed once.** `vpc-workload/main.tf:37,48,61,76,111,119,126` and `state-backend/main.tf:10,18` build names ad hoc, several twice; `state-backend/locals.tf:3-5` does it correctly for lock tables only. Ten of 34 resources are named `this`, including two `for_each` collections (`cognito/main.tf:70,87`).
- **M6. Magic values.** `vpc-workload/main.tf:13` `"enforce"` (ADR 0003 decision, unlinked), `:34` `"resource-name"`, `:135` `"ALL"`, `:137` `60` (AWS allows only 60 or 600, unexplained). `cognito/main.tf:41,51-52` user-facing copy, `:62-63` `5`/`320` (RFC 5321 bound, unexplained), `:101` an auth-flow security policy with no description.
- **M7. Comments restate wiring.** 22 comment lines in 2,515 lines of HCL; 21 are copies of the tag/backend sentence. AWS quirks are uncommented: TGW default-table disabling (`tgw-hub/main.tf:4-9`), `security_group_referencing_support`, the S3 `depends_on` ordering (`state-backend/main.tf:99,117`), and the Cognito MRR guard (`cognito/main.tf:1-10`) cites no ADR although ADR 0011 exists. The single ADR link (`tgw-hub/locals.tf:2`) no longer resolves to one document.
- **M8. Machine enforcement is partial.** No `.tflint.hcl` (naming and documented-variable rules off; the active preset changes with TFLint version), no `.terraform-docs.yml`, no `.pre-commit-config.yaml`, no `.editorconfig`. The docs check is scoped to `terraform/modules` (`terraform-quality.yml:65-72`) and roots have no README, although `github-repository-controls.md:30` lists `terraform_docs` as required for roots. `automation/.../validate-workflows.rb:2-3` claims actionlint runs in CI; it does not.
- **M9. Workflow duplication.** The root `terraform-quality.yml:47-72` re-implements the reusable quality workflow instead of calling it; the policy-check block (`validate-workflows.rb`, `check-reusable-contracts.rb`, `check-action-pins.sh`) is byte-identical in `terraform-pr.yml:23-25` and `terraform-quality.yml:78-80` and runs twice per PR; the reusable plan/apply/drift workflows share 44 identical lines.
- **M10. Duplicated literals.** The MRR status object `{ managed_by_terraform = false, status = "blocked-provider-support" }` is typed by hand in `cognito/outputs.tf:22-25` and `workload-regional/outputs.tf:18-21` and consumed by a test. Route domains as above. The tier list `["dev","staging","prod"]` appears in `state-backend/variables.tf:27`, `terraform-apply.yml:57`, `terraform-apply-caller.yml:14-16`, and six root guards.
- **m.** `1.7.5` in 7 files; `ubuntu-latest` (3) vs `ubuntu-24.04` (10); test fixtures copied between `vpc_workload.tftest.hcl:9-20` and `workload_regional.tftest.hcl:8-19`; placeholder root workflows named `terraform-apply.yml`/`terraform-drift.yml` whose only behaviour is `exit 1`.

### Pillar 3: Pragmatic Programming

- **M11. Layer seams are undefined.** The network root emits `transit_gateway` and `route_table_ids` (`outputs.tf:1-9`) that nothing consumes; workload roots take `ipv4_ipam_pool_id` and `flow_log_kms_key_arn` as tfvars (`variables.tf:29,45`) but no IPAM pool or KMS key producer exists in code; the TGW attachment and cross-account acceptance are missing. Orthogonality holds by omission, not by contract.
- **M12. Contracts fail at apply.** `vpc-workload/locals.tf:10` computes `cidrsubnet` from an IPAM-assigned block; `variables.tf:51` checks only ranges. `subnet_netnum < pow(2, subnet_newbits)`, duplicate `(newbits, netnum)` pairs across AZs, and `ipv4_netmask_length + subnet_newbits <= 28` are all computable at plan and unchecked.
- **M13. Docs drift.** `diagrams.md:7-14,13,35,62-63` shows CloudFront-only ingress, a global Cognito pool, and names `us-east-2`/`eu-west-1` while `README.md:17-18` shows Global Accelerator and per-Region pools and `phase-5-traceability.md:12` says no Region is selected. `phase-3-summary.md:19,22` (3 AZ NAT, Cognito ~$27,500/month) contradicts `cost-estimate.md:42,48` (no NAT, ~$97,350/month at 5M MAU).
- **M14. State history is not a rollback path.** See B4: lifecycle expiry of noncurrent versions, Object Lock optional for prod, no state-restore runbook.
- **M15. Gold-plating and dead abstractions.** Dual locking (`state-backend/outputs.tf:8` `use_lockfile = true` plus the DynamoDB table) with the retirement ADR deferred (`README.md:5`); the unused attachment module; `enable_network_address_usage_metrics = true` (`vpc-workload/main.tf:6`, billable, no ADR); `vpn_ecmp_support` and `security_group_referencing_support` flags with no ADR citation.
- **m.** Action SHA pins repeated across 34 `uses:` lines in 10 files and restated by hand in `action-pin-inventory.md:8-16` with no Dependabot/Renovate config; `feature_plan` accepts `PLUS` although `0006-identity-and-authorization.md:38` defers it; `deletion_protection` accepts `false`.

### Pillar 4: Systems Engineering

- **M16. Cross-Region blast radius in state.** Only `roots/foundation/region-a/shared` exists; state buckets are keyed by tier with no Region dimension and no replication (`state-backend/main.tf:22`). Every region-b root depends on region-a's bucket and lock table, so a region-a S3 or DynamoDB outage blocks every Terraform change including failover-related ones. No per-layer failure-mode table (what breaks, blast radius, detection, response, runbook) exists; `platform.md:41-47` covers the regional-loss narrative only.
- **M17. Validation targets do not match the assumptions and cannot fail on latency.** `operations.md:7-8` sets API p99 250 ms and auth 99.9% / p99 600 ms while `ASSUMPTIONS.md:8-9,12` says p99 200 ms and 99.99%. `verify_public_synthetics.sh:40` asserts HTTP 200 only; the synthetic contract records percentiles with no threshold. The RTO is never bound to a pass/fail gate in `regional-failover.md`.
- **M18. Lifecycle gaps.** No account-decommission runbook (`account-vending.md:31` explicitly excludes closure; ADR 0001's `Suspended` OU has no procedure), no region-evacuation runbook (`adding-region.md` rollback covers a partially added Region only), and the DynamoDB-lock retirement ADR promised in `state-backend/README.md:5` does not exist.
- **m.** `github-repository-controls.md:32` names an `adr_traceability` required check with no implementation; the newer ADRs record dissent as one-line overrides without the dissenter's reasoning; ADR cross-references are bare numbers (`0011:8` cites "ADR 0002", which now names two files).

### Pillar 5: Type-System Thinking

- **M19. An input whose only non-default state is illegal.** `cognito-userpool/variables.tf:106-112` types `replication = { enabled = bool, secondary_region = optional(string), kms_key_arn = optional(string) }`; `main.tf:6` rejects `enabled = true` unconditionally, and `secondary_region` has no allow-list. The type should not admit the state.
- **M20. Boundary invariants are prose.** One `precondition` in 16 directories, no `check` blocks. `vpc-workload/variables.tf:99` accepts a KMS key from any Region (`kms:[^:]+:`); AZ names are free strings never asserted to belong to the provider Region; no root asserts region-a differs from region-b or that only one Region is `primary`. `aws_region` and `aws_account_id` are unvalidated in 8 of 9 roots (only `foundation/.../variables.tf:7` has the Region regex).
- **M21. Tests miss the required trio.** No module has a minimal (required-inputs-only) run; `network_regional.tftest.hcl` has no failing case; `workload_regional.tftest.hcl` never runs `mode = "primary"`, so the Cognito composition and the true branch of `outputs.tf:18` are untested; the Cognito failing case targets a resource precondition, leaving every `var.*` validation unproven.
- **m.** `state-backend/variables.tf:14` is a `map` validated down to exactly three fixed keys (should be an object with three fields); `object_lock = { enabled = bool, retention_mode = optional(...) }` is the two-boolean anti-pattern in object form (`{ enabled = false, retention_mode = "COMPLIANCE" }` is representable and silently ignored); three modules have no `locals.tf` and read `var.*` directly in resources; `vpc-workload/main.tf:89` wraps an already-optional field in `try()`; the reusable pipelines accept any `terraform_version` input, so the `1.7.5` pin is advisory for delivery jobs.

## 5. Remediation plan, in order

**P0. Repository integrity (section 2).** Serialize sessions; choose one ADR series and supersede the other; restore and reconcile the assumptions register; untrack the reference gitlinks; restore `.gitignore`. Nothing below is worth doing on a forked decision record.

**P1. Versions are types (B3).**
- Delete `terraform/.gitignore:2`; regenerate all 16 lock files on one host with `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64`; commit them.
- Change the 7 module constraints to `>= 6.35.0, < 7.0.0`; use the same string in the 9 roots.
- Add `-lockfile=readonly` to every `init` in `scripts/validate-terraform-quality.sh` and `automation/terraform-pipelines/.github/workflows/terraform-{quality,plan,apply,drift}.yml`.
- Make workflows read `.terraform-version` (`terraform_version_file`) instead of restating `1.7.5`; validate the reusable `terraform_version` input against it.
- Decide whether root `terraform.tfvars` are committed (as `phase-5-traceability.md:13` claims) or ignored (as `.gitignore:16` does), and make the doc and the ignore rule agree.

**P2. Contracts at boundaries and reversibility (B4, M12, M19, M20).**
- `vpc-workload`: add validations for `subnet_netnum < pow(2, subnet_newbits)`, uniqueness of `(newbits, netnum)` across AZs, and `ipv4_netmask_length + max(newbits) <= 28`; add a precondition on the flow-log group that the KMS key ARN's Region equals the provider Region; add an AZ-membership precondition.
- Every root: copy the foundation `aws_region` regex and add an `aws_account_id` 12-digit regex; add a closed approved-Region allow-list; assert `identity.mode == "primary"` only for the designated primary Region.
- `cognito-userpool`: remove `replication` until a provider resource exists (keep the `replication_status` output), or type it as a closed variant with a Region allow-list; validate `deletion_protection == true`; restrict `feature_plan` to `ESSENTIALS` until an ADR amendment.
- Add `lifecycle { prevent_destroy = true }` to the state bucket, state KMS key, lock table, and Cognito user pool; require `object_lock.enabled = true` for `prod` by validation; set a floor (for example 90 days) on `noncurrent_version_expiration_in_days`; add `docs/runbooks/state-restore.md`.
- Add a `moved`-block policy to the repository strategy and pin module sources to `git::...?ref=vX.Y.Z` at extraction, with a CI check rejecting relative sources that cross the `modules/terraform-aws-*` boundary.

**P3. Structure (B7, M1 to M4, M10, M11, M15).**
- Delete `internal/network-regional`; call `terraform-aws-tgw-hub` from the network roots.
- Either delete `internal/workload-regional` and compose `vpc-workload` and `cognito-userpool` directly in roots with separate `vpc`, `identity`, `tags` variables, or keep it as the single place the boundary type is declared and make root inputs thin. Mark `interface_endpoints`/`gateway_endpoints` `optional(..., {})` wherever the type is declared so wrapper and leaf agree.
- Collapse the nine roots: one root per layer whose (account, Region, environment) tuple comes from a single `environments` map (or a generator in CI) that also holds tags, Regions, and account IDs. If ADR 0010's root-per-tuple layout must remain, reduce each directory to `backend.tf` plus a four-line `main.tf`.
- Wire `tgw-vpc-attachment` into the workload composition and add the Network-account acceptance/association root, or delete the module and its entry in the quality script. Have the attachment validate `route_domain` against the hub's `route_table_ids` keys so the enum has one source.
- Move the MRR status object into one local in the Cognito module and reference it from the wrapper.
- `state-backend`: replace the exact-three-tier validation with a typed object or a `>= 1` rule; split KMS into its own unit or accept a key ARN per tier; model `object_lock` as `optional(object({ retention_mode, retention_days }))` where `null` means disabled; write the lock-retirement ADR now and drop one of the two lock mechanisms.
- `vpc-workload`: make flow logs an `optional(object({ ... }))` feature with the four resources gated on it.
- Hoist the magic values in M6 into described variables or commented locals; compute all names in `locals`; rename `this` collections by role.

**P4. Machine enforcement (M8, M9, M21).**
- Add `.tflint.hcl` (terraform plugin, preset `all`, `terraform_naming_convention` snake_case, `terraform_documented_variables`/`outputs`, `terraform_standard_module_structure`), `.terraform-docs.yml`, `.pre-commit-config.yaml` (fmt, validate, tflint, terraform-docs, checkov), `.editorconfig`.
- Give every root a README with `BEGIN_TF_DOCS` and extend the docs check to `terraform/roots`.
- Make the root quality workflow a matrix caller of the reusable quality workflow; keep the policy-check block in exactly one workflow; extract checkout/setup/OIDC/backend into a composite action; add actionlint or delete the comment that claims it; add `.github/dependabot.yml` for `github-actions` and generate `action-pin-inventory.md` from the workflows.
- Bring every module to three test runs: `minimal` (required inputs only), `complete`, and at least one `expect_failures = [var.<x>]` per enum or regex validation; add a `primary` run to `workload_regional.tftest.hcl` and a failing case to `network_regional.tftest.hcl`. Add root-level tests (mocked plan) so the eight copies cannot drift silently.

**P5. Systems-engineering documents (B5, B6, B8 to B10, M13, M16 to M18).**
- `docs/traceability.md` with columns Requirement, Design element, Code path, Test, Evidence, one row per 3.1 to 3.6 sub-bullet and Phase 4 to 7 bullet; write "absent" rather than citing prose. Implement the `adr_traceability` check that fails on a missing row or a dangling ADR link.
- `docs/architecture/interfaces.md`: one row per external interface with owner, protocol, encryption, auth, failure mode, detection, runbook.
- A failure-mode table per layer (network/TGW/VPN, edge, identity, compute, data, CI/CD, state backend) in `operations.md`, and an ADR amendment to 0008 deciding state placement per Region or cross-Region replication with break-glass state access.
- A quota table (Cognito RPS, TGW attachments and routes, VPN 1.25 Gbps per tunnel and ECMP aggregate, IPAM pools and allocations, interface endpoints) with default, planned use, headroom threshold, and alarm; close the 5,000 vs 600 RPS gap or amend the assumption.
- `docs/architecture/tracer-bullet.md` naming the slice (foundation + network/region-a + workload-dev/region-a + one Cognito client + one synthetic authenticated call), its exit criteria, and gating region-b, staging, and prod roots on that evidence.
- Skeleton code for the repeated operations: an AFT account-request root, `internal/hybrid-vpn` and `internal/tgw-peering` consumed by the network root, a Region generator, and a real drift caller pointed at a sandbox root.
- Reconcile the SLO table with the assumptions; add p50/p99 thresholds and a latency assertion to the synthetic scripts; bind the RTO to a pass/fail step in the failover runbook.
- Add `account-decommission.md` and `region-evacuation.md` runbooks. Regenerate `diagrams.md` from the README model without concrete Region names; retire the cost section of `phase-3-summary.md` in favour of `cost-estimate.md`.

## 6. Making the pillars enforceable at PR time

The brief requires every PR to state which pillar rules it satisfies and a named reviewer to own each pillar. None of that exists yet. Minimal scaffold:

| File | Purpose |
|---|---|
| `.github/pull_request_template.md` | A checklist with one line per pillar rule; the author ticks the rules the change satisfies and links the ADR. |
| `.github/CODEOWNERS` | Replace the single owner with one team per pillar: `terraform/modules` (SOLID, Type-System), `terraform/roots` and `automation/` (Pragmatic), `docs/adr` and `docs/architecture` (Systems Engineering), everything (Clean Code). |
| `docs/engineering-pillars.md` | The five pillars verbatim, each rule numbered (for example `P5.1` for "no `type = any`") so PRs and this review can cite them. |
| `.tflint.hcl`, `.terraform-docs.yml`, `.pre-commit-config.yaml`, `.editorconfig` | The machine-enforced half of Clean Code and Type-System (naming, docs, formatting, `any` ban via `terraform_typed_variables`). |
| `scripts/check-pillars.sh` | Greps that fail CI: `type = any`, missing `nullable = false`, relative `source` across the registry boundary, missing lock file, open-ended provider constraint, `README.md` missing in a root, ADR number collisions, dangling `A-xx` or `ADR nnnn` references. |
| `docs/traceability.md` plus the `adr_traceability` check | Systems Engineering rule 1 as a required status check. |
