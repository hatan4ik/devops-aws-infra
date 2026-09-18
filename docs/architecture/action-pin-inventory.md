# CI action-pin inventory

**Status:** Phase 6 source inventory. The `hatan4ik/devops-aws-infra` repository enforces full-SHA action pinning; the workflow staging directory is not an active AWS delivery path.
**Resolved:** 2026-09-18 from the named upstream ref using the authenticated GitHub API. A full commit SHA is immutable; the named upstream tag/ref is recorded only for review and must be revalidated before a future remote activation.

| Action | Reviewed upstream ref | Immutable commit used | Workflow use |
|---|---|---|---|
| `actions/checkout` | `v5` | `fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09` | Checkout caller and release-tag revisions. |
| `hashicorp/setup-terraform` | `v3` | `b9cd54a3c349d3f38e8881555d616ced269862dd` | Terraform 1.7.5 installation, matching the locally validated baseline. |
| `terraform-linters/setup-tflint` | `v5` | `ae78205cfffec9e8d93fd2b3115c7e9d3166d4b6` | TFLint installation. |
| `bridgecrewio/checkov-action` | `master` at review | `444c9db6fa75e2d9c19ebf1fde7322089be9009e` | Blocking Terraform policy checks. |
| `aquasecurity/trivy-action` | `master` at review | `d2a0b60797ff03db6132bd4e2b293f9b37081297` | Blocking HIGH/CRITICAL IaC checks. |
| `terraform-docs/gh-actions` | `v1.4.1` | `6de6da0cefcc6b4b7a5cbea4d79d97060733093c` | Generated README drift check. |
| `aws-actions/configure-aws-credentials` | `v5` | `61815dcd50bd041e203e49132bacad1fd04d2708` | AWS OIDC session only; no static AWS keys. |
| `infracost/actions` (`setup`) | `v3` | `e9d6e6cd65e168e76b0de50ff9957d2fe8bb1832` | Base/head Terraform-plan cost diff. |
| `softprops/action-gh-release` | `v2` | `3bb12739c298aeb8a4eeaf626c5b8d85266b0e65` | Publish release only after protected signed tag verification. |

Any new action or pin update requires an owner review of the upstream source, commit provenance, permissions, network behavior, changelog, and a test in a sandbox repository. The quality workflow's own minimal default permission is `contents: read`; only the plan caller adds `id-token: write` and `pull-requests: write`, and only the protected module-release workflow adds `contents: write`.

The use of an immutable SHA follows GitHub's recommendation to pin third-party actions to a full commit SHA. The actual pinned repository and organization ruleset remain a prerequisite, because this local source cannot enforce remote policy.
