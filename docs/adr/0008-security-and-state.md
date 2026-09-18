# ADR 0008: Enforce a layered AWS-native security baseline and isolated Terraform state

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

The platform must enforce high security across accounts, encrypted traffic, central evidence retention, least privilege, and safe Terraform operations. The local reference validates security-by-default, encryption in transit, VPC flow logs, Session Manager, and plan gating but contains legacy broad policies, static credentials, and Terraform Cloud state that conflict with this brief.

## Options considered

1. Per-workload security/logging/state with local IAM users and ad hoc exceptions.
2. A third-party security/state platform as the primary control plane.
3. AWS Organizations/Control Tower preventive controls plus AWS-native detective controls, centralized Log Archive/Security accounts, IAM Identity Center/GitHub OIDC, KMS/Secrets Manager, and S3/DynamoDB Terraform state per environment tier.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** It gives every workload a consistent secure landing zone and defined account ownership. |
| Network Engineer | **Approve 3.** Network evidence, DNS, endpoint, and hybrid controls become organization-wide rather than optional. |
| Security Engineer | **Approve 3.** SCPs prevent common escapes while Config/Security Hub cover service-specific configuration. |
| SRE | **Approve 3.** Central evidence and recoverable versioned state improve incident and restore operations. |
| Platform/DevOps Lead | **Approve 3.** OIDC and state isolation remove static keys and cross-environment blast radius. |

**Result:** 5–0 for option 3; no dissent.

## Decision

Enforce CloudTrail organization trail, Config/conformance packs, GuardDuty, Security Hub, Inspector, IAM Access Analyzer, account-level S3 Block Public Access, EBS default encryption, VPC Flow Logs, and Macie only where PII is confirmed. Use IAM Identity Center for people and GitHub Actions OIDC for machines. Use Session Manager, not inbound SSH/bastions, for managed compute access.

Use per-account/per-environment KMS keys and Secrets Manager rotation. Terraform state is in shared-services S3 buckets separated by environment tier, with SSE-KMS, versioning, restrictive CI/break-glass bucket policies, DynamoDB locking, lifecycle/retention, and Object Lock where required. States contain no avoidable secret values.

## Consequences

- SCP changes are staged in sandbox/non-production and monitored before organization rollout; overly broad deny policies can halt delivery.
- State backend bootstrap is a separately reviewed root and circular-dependency procedure; no backend bucket is created by a root that already relies on it.
- Options 1 and 2 are rejected: decentralization fragments evidence and raises credential risk; a third-party primary control plane conflicts with AWS-native-first and adds avoidable operational cost.
