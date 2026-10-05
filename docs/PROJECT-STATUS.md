# Project status and delivery authority

**Refreshed: 2026-09-29.** This document distinguishes live read-only evidence
from retained historical delivery evidence. It is not a substitute for a fresh
AWS read-only check before an operational decision. The detailed current and
target architecture is in the [architecture overview](ARCHITECTURE.md).

## What is deployed

| Delivery lane | Current scope |
|---|---|
| Organizations | Organization `o-94zz9kms7u` has the six approved top-level OUs and baseline SCPs. All three existing accounts are still directly under the Organization root; no account has been vended or moved by this source. |
| Identity | IAM Identity Center exists in `us-east-1`; its delegated-admin account is `749939210873`. The current human-access model has an `AdministratorAccess` permission set. |
| Delivery identity | GitHub OIDC plan, apply, and drift workflow contracts are present. Their deployment artifacts are a retained control-plane concern, not proof of an application-plane deployment. |
| Sandbox application plane | A 2026-09-29 read-only inventory found no Terraform-tagged VPC, ECS cluster, Cognito pool, ECR repository, or Transit Gateway in `us-east-2`. `platform-tf-lock-table` remains as a Terraform control-plane lock table. |
| Security and cost foundation | No AWS Budgets, organization CloudTrail, or Config aggregator was found through the management account. Root MFA reports disabled for all three accounts and is the first manual security stop condition. |

## What is not deployed

There is no Control Tower landing zone, member-account baseline, central
Security/Audit, Log Archive, or Network account, Transit Gateway, VPN/BGP, second
deployable Region, public endpoint, public load balancer, Route 53 customer
domain, WAF, production environment, or automated regional failover. Those are
roadmap items, not partially supported code paths.

## Operating authority

Only the five roots under [`infra/active`](../infra/README.md) may change AWS.
Each has its own remote-state key, OIDC roles, plan workflow, protected apply
workflow, and non-remediating drift workflow. The supported lifecycle is:

1. Change one active root or pin a released module commit.
2. Review the root-specific GitHub plan and quality checks in a pull request.
3. Merge to protected `main` only after the plan is accepted.
4. Dispatch the matching apply workflow with `confirm=apply` and protected
   environment approval.
5. Prove expected service behavior, then record a no-change plan or drift run.

Do not use local `terraform apply`, console changes, static AWS keys, or state
edits to bypass this lifecycle.

## Current gate

The next infrastructure change is not an application deployment. It is the
landing-zone adoption decision: resolve management root MFA, approve imports
and OU placement for the two existing member accounts, approve the supplied
Security/Audit, Log Archive, and Network account inputs, and review the
root-SCP regional policy drift. See the [architecture overview](ARCHITECTURE.md) and
[roadmap](ROADMAP.md) for the ordered gates.

## Stop conditions

Stop before apply if the caller account/Region is wrong, the remote-state lock
is active, a plan contains an unexpected destroy or replacement, IAM expands
beyond the reviewed requirement, a route becomes public, or required deployment
evidence is missing.
