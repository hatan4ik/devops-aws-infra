# ADR 0006: Use Cognito Essentials MRR and selective Verified Permissions

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

End users need authentication and authorization at million-user scale. The choices must account for Cognito's regional storage, managed replication limitations, adjustable per-Region RPS quotas, MAU pricing, and high-volume authorization cost. Assumptions A-01, A-02, A-04, A-05, and A-14 apply.

## Options considered

1. One regional Cognito user pool with custom user/password replication to another Region; IAM roles/claims only for all authorization.
2. A self-managed IdP on ECS/EKS with a global relational store; a custom authorization service.
3. Cognito Essentials with managed MRR to one secondary Region and multi-Region KMS key; local JWT coarse checks plus Amazon Verified Permissions for selected fine-grained decisions; IAM roles for service-to-service access.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** It eliminates a bespoke password-replication and IdP operations problem. |
| Network Engineer | **Approve 3.** Cognito custom-domain health routing and dynamic SDK endpoint selection integrate with regional failover. |
| Security Engineer | **Dissent: prefer Cognito Plus.** Adaptive threat protection could be needed, but no threat-model/business budget justifies it yet. |
| SRE | **Approve 3.** MRR's primary/secondary behavior is testable and managed; quota alarms are mandatory. |
| Platform/DevOps Lead | **Approve 3.** JWT checks protect the common path; AVP scopes expensive centralized decisions to where they add value. |

**Result:** 4–1 for option 3.

## Decision

Use Cognito Essentials with one MRR secondary user-pool replica. Set a multi-Region customer-managed KMS key, custom domain, health check, regional email/SMS configuration, and active-secondary status. Plan 300 UserAuthentication RPS in each Region. Configure token validation with the MRR-compatible issuer and JWKS refresh behavior; APIs must accept only expected issuer, audience, signature, expiry, scopes, and tenant claims.

Use Cognito groups/scopes/custom claims for local coarse authorization. Use Amazon Verified Permissions/Cedar for selected resource-level decisions, batch where appropriate, and cache only within a documented revocation bound. Use IAM roles for AWS/service-to-service authorization; never map end users to broad IAM permissions.

## Consequences

- Essentials MRR at the 1M-MAU assumption costs about $19,350/month; 180 purchased RPS above the 120-RPS default in each Region costs about $7,200/month. At 5M MAU the Essentials+MRR baseline is about $97,350/month.
- Secondary Cognito limitations are product requirements: no signup/password reset/profile edits there, eventual directory replication, and no TOTP MFA in secondary. Any unacceptable limitation reopens this ADR.
- Options 1 and 2 are rejected: custom password replication is security-sensitive and self-managed identity has higher operational/patching/recovery burden. Cognito Plus is deferred pending a threat model and budget approval.
