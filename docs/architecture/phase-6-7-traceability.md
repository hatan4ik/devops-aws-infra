# Phase 6–7 delivery and verification traceability

**Status:** The credential-free quality source and root workflow are published in
`hatan4ik/devops-aws-infra`. Protected `main`, four deployment environments,
and a sandbox permissionless AWS OIDC proof are live under ADR 0017. No
Terraform backend, resource-permissioned delivery role, canonical AWS plan,
apply, or application deployment exists. ADR 0015 records the legacy state
bootstrap and a source-only adoption path; it is not a deployed application
platform. “Implemented” means committed source unless this document explicitly
records remote proof.

| Brief requirement | Local evidence | Status and remaining gate |
|---|---|---|
| CI/CD: Terraform formatting, validation, lint, tests, Checkov, Trivy, and generated-doc checks | [root quality workflow](../../.github/workflows/terraform-quality.yml), module tests, action-pin inventory. | Remote required-check and `main` branch-protection enforcement verified. The workflow itself remains credential-free. |
| CI/CD: plan review, cost diff, deployment approval gates, no static AWS keys | [`terraform-plan.yml`](../../automation/terraform-pipelines/.github/workflows/terraform-plan.yml), [`terraform-apply.yml`](../../automation/terraform-pipelines/.github/workflows/terraform-apply.yml), [ADR 0012](../adr/0012-oidc-gated-terraform-delivery.md), [ADR 0017](../adr/0017-github-oidc-bootstrap-proof.md). | Environments and sandbox OIDC trust proof are verified. Needs a backend, root-specific least-privilege role policy, environment-scoped backend configuration, and approved non-production plan before activation. |
| CI/CD: drift detection without automatic remediation | [`terraform-drift.yml`](../../automation/terraform-pipelines/.github/workflows/terraform-drift.yml), [ADR 0012](../adr/0012-oidc-gated-terraform-delivery.md). | Implemented as source. Needs a read-only role, schedule/caller, alert route, and an intentionally introduced sandbox drift test. |
| CI/CD: module release through signed semantic tags | [`module-release.yml`](../../automation/terraform-pipelines/.github/workflows/module-release.yml), [`module-release-caller.yml`](../../automation/terraform-pipelines/templates/module-release-caller.yml). | Implemented as source. Needs independent module repositories, tag/ruleset protection, signer trust, protected environment, and first approved release. |
| Action supply chain | [Full SHA inventory](action-pin-inventory.md); all third-party `uses:` in reusable workflows resolve to 40-character commits. | Source uses full commit SHAs and the published repository enforces mandatory SHA pinning. |
| Account vending / Region expansion / VPN-BGP / failover / emergency access operations | [Runbook index](../runbooks/README.md), [account vending](../runbooks/account-vending.md), [Region](../runbooks/adding-region.md), [hybrid](../runbooks/hybrid-vpn-bgp-onboarding.md), [failover](../runbooks/regional-failover.md), [break-glass](../runbooks/break-glass-access.md). | Documented. Target identifiers, owners, change system, and remote controls remain required. |
| Network connectivity, VPN/BGP health, endpoints, Flow Logs | [`verify_network_read_only.sh`](../../tests/post_deploy/verify_network_read_only.sh), hybrid onboarding runbook. | Implemented read-only script; cannot run until a target account/Region and approved read role exist. |
| Security integration checks | [`verify_security_read_only.sh`](../../tests/post_deploy/verify_security_read_only.sh), account-vending runbook. | Implemented read-only script; needs Security/Audit delegated-admin account, Config recorder name, and live findings. |
| Low-latency application AuthN/AuthZ and regional routing verification | [`verify_public_synthetics.sh`](../../tests/post_deploy/verify_public_synthetics.sh), [AuthN/AuthZ contract](../../tests/post_deploy/auth-api-synthetic-contract.md), failover runbook. | Public smoke script is implemented; full auth/authorization/failover needs approved endpoint URLs, protected synthetic user, application contract, MRR resolution, and a staging game day. |
| Explicit no-automatic-disruption testing rule | [ADR 0013](../adr/0013-layered-verification-no-automatic-fault-injection.md). | Accepted. Controlled live testing starts only under a specific change/incident authorization. |

## Hard blockers before a production-ready claim

1. Cognito MRR is blocked by current Terraform provider capability under ADR 0011. It has not been deployed, tested, or substituted with imperative automation.
2. No approved platform accounts, Regions, CIDRs, ASNs, IPAM pools, VPN customer gateways, DNS/certificates, identity roles, service quotas, data model, application image, or synthetic test identity has been supplied or created. The legacy bootstrap’s adoption is selected in [ADR 0015](../adr/0015-adopt-legacy-state-bootstrap.md), but it cannot be used as an approved delivery backend until state-address migration and hardening evidence are accepted.
3. The GitOps source has protected `main`, deployment environments, and a sandbox OIDC trust proof, but it has no backend configuration, Terraform role permissions, release control, target-organization repository family, or approved plan. The staged AWS delivery workflows remain disabled until root-specific controls and a sandbox plan are in place.
4. No live network/security/authentication/failover assertion has run. The module tests and syntax/static checks are not deployment evidence.
