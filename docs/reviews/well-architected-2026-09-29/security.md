# Security Pillar Assessment

## Executive Summary

The account baseline contains strong delivery primitives—federated human access,
GitHub OIDC trust constraints, no root access keys, encrypted state storage,
and public-access blocks. It is nevertheless **high risk** because root MFA,
organization logging, threat detection, central findings, account placement,
and alternate contacts are incomplete. The current environment is not suitable
for a production application handling large user populations.

**Risk profile:** High 5; Medium 2; Improvement opportunities 2.

AWS Well-Architected detection guidance calls for standardized logs, findings,
metrics, alert correlation, and remediation. [Security Pillar — Detection](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/detection.html)

## Detailed findings

### SEC-01 — Root MFA is disabled across all accessible accounts

1. **Risk level:** High / P0.
2. **Description:** `iam:GetAccountSummary` reported `AccountMFAEnabled=0` for
   Management `915507704945`, Identity `749939210873`, and Sandbox
   `448871779014`. Root access keys were not present, which is positive, but
   does not offset missing MFA.
3. **Affected resources:** AWS account root users for all three accounts.
4. **Best-practice reference:** [AWS root-user best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html).
5. **Business impact:** Compromise of a root password or recovery channel can
   compromise the account and organization.
6. **Recommendation:** Enable root MFA immediately, beginning with Management;
   use phishing-resistant passkeys/security keys where available and document
   split recovery ownership.
7. **Implementation steps:** Manual root-user console action only. Do not
   create root access keys or place root credentials/MFA seeds in source
   control. Re-run `aws iam get-account-summary` with each approved SSO profile
   afterwards to verify `AccountMFAEnabled=1`.
8. **Estimated effort:** Low.
9. **Expected outcome:** Root login requires a second factor and satisfies the
   fundamental account-security prerequisite.

### SEC-02 — Sandbox IAM user has an active long-lived access key without MFA

1. **Risk level:** High / P0.
2. **Description:** The Sandbox credential report aggregates to one IAM user,
   one active access key, no MFA, and no console password. The user name and
   key identifier were intentionally excluded from this report.
3. **Affected resources:** One IAM user and one active access key in Sandbox
   account `448871779014`.
4. **Best-practice reference:** [IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html).
5. **Business impact:** A leaked key can create resources, exfiltrate data, or
   bypass the normal SSO/OIDC delivery boundary within its permissions.
6. **Recommendation:** Identify the key owner in a secure session, determine
   whether the use case is a workload integration, and replace it with a
   short-lived role or scoped workload credential. Disable/rotate the key on a
   planned cutover.
7. **Implementation steps:** Generate an IAM credential report in a secure
   operator session; map the key to a business owner; test a replacement role;
   disable the key; monitor CloudTrail after central logging is live; delete it
   when no longer used.
8. **Estimated effort:** Medium.
9. **Expected outcome:** No unmanaged human long-lived access key remains.

### SEC-03 — Organization CloudTrail and central log archive are absent

1. **Risk level:** High / P0.
2. **Description:** Management `cloudtrail describe-trails --include-shadow-trails`
   returned zero trails. There is no dedicated Log Archive account yet.
3. **Affected resources:** Entire Organization; all current and future member
   accounts.
4. **Best-practice reference:** [SEC04-BP01 Configure service and application logging](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec_detect_investigate_events_app_service_logging.html).
5. **Business impact:** There is no durable, centralized forensic record of
   API activity or data events; incident investigation and compliance evidence
   are materially weakened.
6. **Recommendation:** Create a Log Archive account and a multi-Region
   organization trail with log-file validation, KMS-encrypted/versioned Object
   Lock storage, least-privilege bucket policy, and security alerting.
7. **Implementation steps:** First create Log Archive through the approved
   account-vending path; then introduce a dedicated logging root with isolated
   state, OIDC role, trail, bucket policy, retention/lifecycle, and validation
   tests. Add CloudWatch/Lake integration only where it has an approved query
   or alerting use case.
8. **Estimated effort:** High.
9. **Expected outcome:** Durable API audit evidence across the Organization.

### SEC-04 — Threat detection and central findings are not enabled

1. **Risk level:** High / P0.
2. **Description:** GuardDuty detector count is zero in accessible
   `us-east-2`; Management Security Hub returns `InvalidAccessException`
   because it is not subscribed; no Config aggregator exists. Management
   `us-east-1` has one Config recorder/delivery channel, but it excludes IAM
   resource types and does not aggregate member accounts.
3. **Affected resources:** Management, Identity, Sandbox, and all future
   accounts/Regions.
4. **Best-practice reference:** Security Pillar detection and centralized
   findings guidance.
5. **Business impact:** Malicious activity, configuration drift, and security
   posture changes can remain undetected or fragmented by account.
6. **Recommendation:** Delegate GuardDuty, Security Hub, and Config aggregation
   to the future Security/Audit account; enable required Regions/accounts and
   route high-severity actionable findings to an owned notification path.
7. **Implementation steps:** Define severity, triage owner, suppression policy,
   retention, response playbooks, and costs before enabling services. Validate
   one test finding and one Config non-compliance event end to end.
8. **Estimated effort:** High.
9. **Expected outcome:** Central, actionable detection rather than isolated or
   absent security signals.

### SEC-05 — Member accounts remain at Organization root; SCP policy is inconsistent

1. **Risk level:** High.
2. **Description:** Identity and Sandbox accounts are direct children of
   `r-1oii`, so OU-specific guardrails are not effective. The root-attached
   `AdvancedModeRegionRestrictionSecurityControlPolicy` permits only a small
   action subset in `us-west-2`, denying VPC/TGW operations, while repository
   intent expects `us-west-2` as an approved future US Region.
3. **Affected resources:** Member accounts `749939210873` and `448871779014`;
   root SCP `p-emzb3prn`; all approved OUs.
4. **Best-practice reference:** [AWS SCP testing guidance](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html).
5. **Business impact:** Intended security controls do not apply consistently;
   future multi-Region deployment will fail unpredictably or prompt an unsafe
   broad policy removal.
6. **Recommendation:** Import/adopt and move the member accounts one at a
   time, then replace—not delete—the advanced root policy with a tested US-only
   region SCP at OU scope. Retain organization-escape and managed-role
   protections.
7. **Implementation steps:** Review effective policy impact; test read-only
   VPC/TGW APIs in Sandbox; attach replacement at the target OU; verify US
   Regions allowed and non-US Regions denied; detach the old root policy only
   after evidence is accepted.
8. **Estimated effort:** High.
9. **Expected outcome:** Predictable least-privilege regional governance.

### SEC-06 — Account contacts and financial-alert contacts are absent

1. **Risk level:** Medium.
2. **Description:** Management Security alternate contact returns
   `ResourceNotFound`; earlier read-only checks found no Budget objects in any
   accessible account. Billing and Operations contacts were also not found or
   could not be confirmed.
3. **Affected resources:** All three current accounts.
4. **Best-practice reference:** AWS account contact and budget-alert guidance.
5. **Business impact:** Security/billing notifications may not reach an owner;
   abnormal spending may be detected late.
6. **Recommendation:** Configure Security, Billing, and Operations contacts as
   maintained group mailboxes and establish organization/account budgets with
   multiple recipients.
7. **Implementation steps:** Maintain contact ownership outside the repository;
   create a $500 initial consolidated budget, 80% actual and 100% forecast
   alerts; test notification delivery; add Cost Anomaly Detection.
8. **Estimated effort:** Low.
9. **Expected outcome:** Clear contact and financial-event escalation.

### SEC-07 — IAM password policy is not configured, though no console IAM users were found

1. **Risk level:** Medium.
2. **Description:** `GetAccountPasswordPolicy` returns `NoSuchEntity` in all
   three accounts. Management and Identity have zero IAM users; Sandbox has one
   user without a console password. The immediate risk is lower than SEC-02,
   but a future IAM console user would inherit no account password standard.
3. **Affected resources:** Account password policies; future IAM users.
4. **Best-practice reference:** IAM password policy guidance.
5. **Business impact:** If local IAM console users are introduced, password
   strength and rotation controls may be inconsistent.
6. **Recommendation:** Prefer IAM Identity Center and prohibit new IAM human
   users. Configure a strong account policy as defense in depth only where IAM
   console users remain unavoidable.
7. **Implementation steps:** First inventory the Sandbox IAM user's actual
   use; document an exception process; then set the account policy only if
   local console access is retained.
8. **Estimated effort:** Low.
9. **Expected outcome:** Federation remains the default human-access model.

## Improvement opportunities

| Opportunity | Verified evidence | Recommendation |
|---|---|---|
| Federated delivery is sound. | 13 discovered GitHub OIDC roles have audience and repository-subject constraints; no static credential patterns were found in repository source. | Maintain environment/ref restrictions and review trust policies whenever a workflow is added. |
| Control-plane storage has a strong baseline. | Public access blocked; observed state buckets use encryption, versioning, KMS/Object Lock where applicable; DynamoDB locks use KMS. | Reuse the pattern for Log Archive and Security/Audit, with access boundaries and retention documented. |

## Prioritized action plan

1. **0-30 days:** Resolve SEC-01 through SEC-04 and SEC-06 before deploying a
   workload.
2. **30-90 days:** Resolve account adoption/SCP policy, centralize detective
   controls, and eliminate the IAM-user exception.
3. **90+ days:** Add application secrets, TLS, WAF, workload IAM, VPC endpoint,
   data-classification, and incident-response controls as services are added.
