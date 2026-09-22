# Phase 4: Repository and code strategy

The authoritative repository and module topology is
[ADR 0010](../adr/0010-repository-and-module-topology.md) and its companion
[repository strategy](repository-strategy.md). This repository is a
credential-free GitOps source and candidate implementation package; publishing
it does not create the proposed repository family, branch protections, GitHub
environments, releases, OIDC roles, or AWS resources.

Only three modules are candidates for independent release after the required
extraction criteria are satisfied: `terraform-aws-vpc-workload`,
`terraform-aws-tgw-hub`, and `terraform-aws-cognito-userpool`. The current
candidate source for them and for internal composition is under
[`infra/candidates/`](../../infra/README.md#candidates).

The [`archive/prototypes/`](../../archive/prototypes/) directories are disabled historical
prototypes, not an alternative monorepo topology. Their source must not be
copied into a target repository or delivery workflow; see
[ADR 0014](../adr/0014-canonical-architecture-and-iac-boundary.md).
