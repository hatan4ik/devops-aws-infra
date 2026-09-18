# ADR 0008: Observability Architecture

## Status
Accepted

## Context
Need to define SLOs, trace requests across regions, and alert SREs.

## Options Considered
1. **Centralized Observability Account (CloudWatch Cross-Account)**.
2. **Decentralized CloudWatch (Per Account)**.
3. **Third-Party (Datadog/New Relic)**.

## Decision
**Centralized Observability Account via CloudWatch**

We will configure CloudWatch cross-account observability to sink logs, metrics, and X-Ray traces to a dedicated `Shared Services` or `Observability` account.

## Consequences
* **Positive**: Single pane of glass without paying third-party licensing fees.
* **Negative**: CloudWatch UI is sometimes less intuitive than Datadog.
* *Dissenting*: *DevOps Lead* wanted Datadog. Overruled by financial constraints.
