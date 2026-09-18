# ADR 0001: Govern accounts with Control Tower and Account Factory for Terraform

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

The platform needs a governed multi-account landing zone, preventive controls, delegated security administration, and account vending as code. The local reference supports composable components and controlled deployment; the GitHub reference includes the AWS-supported Account Factory for Terraform (AFT). Assumptions A-08 and A-11 apply.

## Options considered

1. AWS Organizations and custom Terraform account vending/SCPs only.
2. AWS Control Tower Account Factory console requests and manual customization.
3. AWS Control Tower with AFT, a dedicated AFT management account, GitOps account-request/customization repositories, and additional Terraform-managed SCPs.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** Control Tower supplies the supported governance baseline while AFT provides repeatable account vending. |
| Network Engineer | **Approve 3.** A distinct Network account and deterministic account requests simplify RAM/TGW ownership. |
| Security Engineer | **Dissent: prefer 1.** AFT's privileged bootstrap and its supporting services enlarge the control plane; it must be constrained and audited. |
| SRE | **Approve 3.** Account lifecycle and baseline changes become observable, repeatable operations instead of tickets and console drift. |
| Platform/DevOps Lead | **Approve 3.** GitOps requests and customizations align with the requested GitHub delivery model. |

**Result:** 4–1 for option 3.

## Decision

Use AWS Control Tower for the landing-zone baseline and AFT for account vending as code. AFT receives its own Platform OU and dedicated account; it is not the Management, Security, Network, or Shared Services account. Bootstrap is a one-time, separately approved action. Account requests are pull-request reviewed and include OU, account owner, cost tags, enabled Regions, baseline stack-set/customization version, and workload classification.

Initial OUs: `Security`, `Platform`, `Workloads/Production`, `Workloads/NonProduction`, `Sandbox`, and `Suspended`. Initial foundational accounts: Management, Log Archive, Security/Audit, Identity, Network, Shared Services, and AFT Management. Workloads receive separate dev, staging, and production accounts; more workload accounts are vended from the same contract.

SCP baseline: deny organization escape; restrict member-account root activity; deny unapproved Regions; deny disabling/deleting CloudTrail, Config, GuardDuty, Security Hub, Inspector, and log/archive protections; deny public S3; and restrict unencrypted creation where AWS exposes a reliable condition key. SCPs do not apply to the Management account, so its root user is separately MFA-protected, has no access keys, alerts on use, and is held by organization-controlled recovery contacts. Service control policies are not the sole encryption enforcement: Config rules, service policies, and Terraform checks cover service-specific semantics.

## Consequences

- Control Tower/AFT service and bootstrap prerequisites must be verified before implementation; AFT's administrator bootstrap must never become a daily CI credential.
- Account provisioning is subject to Control Tower/AFT constraints and lead time; no direct account creation is permitted from workload pipelines.
- The design retains an explicit recovery/break-glass path and CloudTrail evidence.
- Options 1 and 2 are rejected: custom-only vending recreates a landing-zone control plane; console-only vending is not account vending as code.
