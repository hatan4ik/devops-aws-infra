# ADR 0004: AuthN / AuthZ Provider

## Status
Accepted

## Context
We need to authenticate 5 million MAU with a peak of 5,000 RPS for auth. The solution must support multi-region.

## Options Considered
1. **Amazon Cognito User Pools**: AWS-native, fully managed, pay-per-MAU.
2. **Auth0 / Okta**: SaaS leaders in IAM.
3. **Self-Managed IdP (e.g., Keycloak on ECS)**: Full control, fixed infrastructure cost.

## Decision
**Amazon Cognito User Pools**

We will use Cognito User Pools. To handle multi-region Active-Active, we will use an EventBridge/Lambda-based synchronization mechanism (or a single global Cognito pool routed via CloudFront, depending on latency tests), but default to regional pools synced via custom logic since Cognito does not natively support Active-Active global tables.

## Consequences
* **Positive**: Extremely cost-effective for 5M MAU compared to Auth0. Deep AWS integration (API Gateway/ALB).
* **Negative**: Cognito multi-region replication is not native and requires custom Lambda triggers. Quotas for 5,000 RPS will require a significant AWS support limit increase.

## Dissenting Opinions
* *Security Engineer*: Warned that custom multi-region sync for Cognito introduces security edge cases.
* *Resolution*: Acknowledged. We will document the scaling ceiling and engage AWS Support for the 5k RPS quota. If replication proves too brittle during Phase 7 chaos testing, we will pivot to a single-region Cognito pool behind Global Accelerator.
