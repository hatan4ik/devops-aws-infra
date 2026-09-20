# Phase 4 requirement traceability

| Brief requirement | Evidence | Status |
|---|---|---|
| GitHub as the platform | [Repository strategy](repository-strategy.md); [repository controls](github-repository-controls.md); [ADR 0017](../adr/0017-github-oidc-bootstrap-proof.md). | Protected `main`, protected deployment environments, and a permissionless sandbox OIDC proof are configured. No release control or root-specific Terraform delivery permission exists. |
| Lowercase, hyphenated module/root/docs/pipeline naming | [Naming contract](repository-strategy.md#naming-contract); [assumption A-16](../ASSUMPTIONS.md). | Designed; organization slug awaits confirmation. |
| Final repository list with one-line purpose | [Proposed final repository set](repository-strategy.md#proposed-final-repository-set). | Designed; workload repositories remain a per-app family until an app is named. |
| Create module repositories only where lifecycle is independent; otherwise `modules/` in a monorepo | [Split rationale and layout](repository-strategy.md#why-the-split-is-deliberately-small); [ADR 0010](../adr/0010-repository-and-module-topology.md); [A-18](../ASSUMPTIONS.md). | The source repository exists; the dedicated module and live-root repositories are not created. |
| Branch protection, CODEOWNERS, required checks, signed commits, semantic-version tags on module repositories | [Mandatory protection profile](github-repository-controls.md#mandatory-main-ruleset--branch-protection-profile); [checks](github-repository-controls.md#required-checks-by-repository-type); [tags](github-repository-controls.md#tags-releaplatform-and-supply-chain-controls). | Planned configuration only; requires explicit remote-change approval and organization preflight. |
| ADR with five-reviewer quorum and rejected alternatives | [ADR 0010](../adr/0010-repository-and-module-topology.md). | Complete as a design recommendation. |

The Phase 4 strategy was stakeholder-approved on 2026-09-18. Its Phase 5–7 source is now published, but target organization-specific repositories and GitHub controls require confirmed team, ownership, environment, and AWS identity inputs before they can be safely configured.
