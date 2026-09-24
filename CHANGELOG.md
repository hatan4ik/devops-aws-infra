# Changelog

All notable GitOps-source changes are recorded here.

## Unreleased

### Changed

- Reduced the repository to one executable delivery path: the five roots under
  `infra/active`, their GitHub OIDC workflows, bootstrap prerequisite, tests,
  scripts, and current operator documentation.
- Replaced the sprawling documentation set with current project status, ConOps,
  roadmap, module catalog, canonical ADR index, and five operational runbooks.
- Made the delivery-boundary guard reject retired source directories if they
  reappear.
- Replaced unsafe legacy break-glass guidance with an SSO/OIDC-compatible,
  least-privilege emergency procedure.

### Removed

- Unapproved candidate roots, disabled prototypes, retired CloudFormation and
  workflow copies, copied third-party reference repositories, review snapshots,
  duplicate ADRs, obsolete runbooks, and one-shot remediation scripts.
- Regenerated Terraform provider/module caches from the working tree. The
  repository uses ignored local caches only during validation.

Retired material remains recoverable from Git history and is not an alternate
implementation or delivery path.
