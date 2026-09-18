# ADR 0013: Use layered verification with no automatic fault injection or drift remediation

**Status:** Accepted — Phase 7 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

The platform has private multi-account routing, VPN/BGP, encryption, central security services, a low-latency API, and multi-Region recovery objectives. Static checks alone cannot prove deployed connectivity or recovery, while automatic fault injection or repair can turn verification into a production incident. The workspace does not contain an approved account, Region, application endpoint, synthetic identity, or permission boundary, so verification must not invent or exercise them.

## Options considered

1. Treat Terraform formatting, validation, and static policy scans as sufficient production proof.
2. Automatically inject regional/network/identity faults and automatically remediate drift from CI on every change.
3. Run credential-free module/static checks before merge; require post-deployment read-only AWS/public checks with explicit identifiers; use isolated synthetic AuthN/AuthZ identities in staging; and run change-approved, observed regional-failover and VPN/BGP game days with manual rollback ownership.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** The approach distinguishes a valid module interface from an actually functioning multi-Region platform. |
| Network Engineer | **Approve 3.** Route isolation and BGP convergence need target-account evidence, while uncontrolled fault injection could leak traffic across domains. |
| Security Engineer | **Approve 3.** Strict active HIGH/CRITICAL finding checks and redacted synthetic evidence prevent verification from exposing secrets or normalizing risk. |
| SRE | **Approve 3.** Measured, approved game days create credible RTO/RPO evidence and preserve a clear incident commander/rollback role. |
| Platform/DevOps Lead | **Approve 3.** The test layers are automatable where safe and explicitly controlled where they touch live availability or credentials. |

**Result:** 5–0 for option 3; no dissent.

## Decision

Adopt option 3. `terraform test` with mocks, Terraform validation, TFLint, Checkov, Trivy, and generated-documentation drift run before merge. The post-deployment network and security scripts make only AWS CLI read calls, require supplied deployed IDs/Region, and fail closed. Public synthetics use only HTTPS endpoints. The full AuthN/AuthZ journey uses a protected, non-human staging identity and stores no credential/token or customer data in source/artifacts.

Regional failover, VPN/BGP path withdrawal, data recovery, and Cognito MRR validation are change-approved game-day actions in the runbooks. They are not scheduled by CI, and the MRR test remains blocked until ADR 0011's provider-backed deployment condition is satisfied.

## Consequences

- Option 1 is rejected: source-level checks cannot demonstrate IAM, routing, VPN tunnel state, central security evidence, endpoint health, or application authorization behavior after deployment.
- Option 2 is rejected: automated disruptive tests/remediation could create an unbounded availability, routing, identity, or data incident and obscure the responsible change.
- Passing local/module tests does not assert AWS readiness. The selected account/Region, exact service quotas, deployment credentials, synthetic identities, endpoint URLs, central security services, and a measured staging game day remain mandatory evidence.
