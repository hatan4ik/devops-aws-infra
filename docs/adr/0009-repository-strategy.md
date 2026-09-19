# ADR 0009: Repository Strategy for Infrastructure Code

## Status
Superseded by [ADR 0014](0014-canonical-architecture-and-iac-boundary.md)

> Historical record only. The active repository and module topology decision is
> [ADR 0010](0010-repository-and-module-topology.md).

## Context
We need to define the repository structure for our Terraform infrastructure code, balancing module reusability, CI/CD pipeline complexity, and release management. The naming convention provided is:
- `terraform-aws-<component>` (for reusable modules)
- `<org>-aws-platform-<layer>` (for roots)

## Options Considered
1. **Full Multi-Repo**: Every module and every root layer gets its own repository.
2. **Strict Monorepo**: All modules and root deployments live in a single repository.
3. **Hybrid Monorepo (Selected)**: Reusable modules with an *independent lifecycle* (e.g., networking hub, security baseline) get their own `terraform-aws-<component>` repositories. Root deployments and tightly coupled modules live in a single monorepo (`<org>-aws-platform-roots`), split by layer directories.

## Decision
**Hybrid Monorepo Model**

We will create dedicated repositories **only** for core foundational modules that have an independent lifecycle and will be consumed across multiple teams or decoupled environments. 
- Core modules (e.g., `terraform-aws-tgw-hub`, `terraform-aws-vpc-workload`) will have their own repos and be versioned via Git tags.
- Root layers (`-org`, `-network`, `-security`, `-identity`, `-workload`) will live in a single root platform monorepo (`platform-aws-platform-roots`) under separate directories. 
- Any bespoke module that is only used by one workload will stay in the `modules/` folder of the monorepo.

## Consequences
* **Positive**: Minimizes repository sprawl. Foundational components are strictly version-controlled to prevent accidental breaking changes to downstream consumers (SOLID: Open/Closed principle). Root state deployments are centralized, simplifying the CI/CD GitHub Actions setup for `plan`/`apply`.
* **Negative**: Requires slightly more complex CI/CD path-filtering in the root monorepo to ensure changes to `-security` don't trigger plans in `-network`.

## Dissenting Opinions
* *DevOps Lead*: Full multi-repo allows granular RBAC via GitHub repo permissions.
* *Resolution*: Overruled by Platform Lead. Managing 50+ repos for a platform of this size introduces massive overhead for dependabot and PR reviews. Granular RBAC can be enforced via CODEOWNERS inside the monorepo instead.
