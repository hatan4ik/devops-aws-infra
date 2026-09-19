# ADR 0007: Fine-Grained Authorization

## Status
Superseded by [ADR 0014](0014-canonical-architecture-and-iac-boundary.md)

> Historical record only. The active identity and authorization decision is
> [ADR 0006](0006-identity-and-authorization.md).

## Context
Application requires authorization beyond standard API Gateway/ALB JWT validation.

## Options Considered
1. **Amazon Verified Permissions (Cedar)**: AWS managed authorization service.
2. **In-App RBAC/ABAC**: Handled entirely in application code.
3. **IAM-based Authorization**: Using AWS IAM for app-level auth.

## Decision
**Amazon Verified Permissions**

## Consequences
* **Positive**: Decouples authorization logic from application code. Uses standard Cedar language.
* **Negative**: Adds a network hop for auth checks.

## Dissenting Opinions
* *SRE*: Concerned about latency for the extra network hop.
* *Resolution*: AVP promises millisecond latency. We will test during tracer bullet phase; if latency > 10ms consistently, we fallback to local evaluation of Cedar policies within the app.
