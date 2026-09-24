# ADR 0010: Use a hybrid repository topology with three independently released modules

**Status:** Accepted — Phase 4 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

**Implementation note (2026-09-22):** This ADR records the Phase 4 design
decision, not the current repository inventory. The delivered topology is
authoritatively documented by the [repository map](../../README.md#repository-map)
and [module catalog](../MODULE-REPOSITORIES.md): active root composition stays
in this GitOps repository and reusable implementations are published as
versioned `aws.modules.*` repositories. Treat the proposed `<org>` family
below as historical design reference until a later ADR explicitly revives it.

## Context

The platform needs clear ownership, independently deployable account/Region/environment roots, reusable Terraform modules, and GitHub controls that make changes auditable. Phase 1–2 references show useful modular patterns but also demonstrate the cost of over-generalizing a module before its interface has stable consumers. The brief requires GitHub, a specific naming convention, and module repositories only where the lifecycle is independent.

## Options considered

1. One monorepo containing every root, module, documentation artifact, and reusable workflow.
2. One repository for every Terraform module and every platform layer from the beginning.
3. A hybrid: three stable reusable-module repositories (`terraform-aws-vpc-workload`, `terraform-aws-tgw-hub`, and `terraform-aws-cognito-userpool`); separate root repositories by organization, foundation, network, security, identity, and application; plus dedicated documentation and reusable-workflow repositories. Keep immature composition modules beside their live roots until the defined extraction threshold is met.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** The split reflects platform blast-radius boundaries and preserves a stable contract for the three cross-cutting components. |
| Network Engineer | **Approve 3.** The TGW and workload-VPC contracts need independent consumer compatibility, while Resolver/VPN composition should stay with the network root initially. |
| Security Engineer | **Approve 3.** Separate security/identity roots and central GitHub controls give review ownership without turning every policy fragment into a repository. |
| SRE | **Approve 3.** Environment roots can be planned, promoted, and rolled back independently; a monorepo would force unrelated plans and increase operational coupling. |
| Platform/DevOps Lead | **Approve 3.** Semantic module releases, immutable dependency references, and a workflow repository provide reusable delivery without premature module maintenance overhead. |

**Result:** 5–0 for option 3; no dissent.

## Decision

Adopt the delivered topology: this GitOps repository owns active root
composition and root-specific workflows; reusable implementations with an
independent lifecycle live in versioned `aws.modules.*` repositories. Every
consumer pins a signed release commit. New capabilities are introduced as a
reviewed active root, not kept as a parallel draft tree.

Require a root for each `(account, Region, environment)` deployment tuple, module inputs rather than cross-team remote-state reads, semantic and signed module tags, protected `main`, CODEOWNERS, two approvals including a code owner, required checks, and GitHub OIDC rather than long-lived AWS credentials. ADR 0017 establishes the initial personal-repository controls and a permissionless sandbox trust proof; root-specific delivery roles, backend configuration, and independent reviewers remain uncreated. The two-approval target cannot be met until independent GitHub reviewers are added.

## Consequences

- Option 1 is rejected: it has a low initial setup cost, but it couples unrelated plans, review queues, releases, and least-privilege deployment credentials.
- Option 2 is rejected: it creates versioning, ownership, release, and compatibility obligations before modules have independent consumers or stable interfaces.
- A new module cannot be extracted merely to remove duplication. It needs an
  ADR, semantic-version/migration plan, owners, tests, and consumer migration
  evidence.
- This decision does not authorize GitHub repository creation, branch/ruleset changes, tags, workflow execution, AWS role creation, Terraform initialization, plan, or apply. Those are separately controlled Phase 4 remote and later implementation actions.
