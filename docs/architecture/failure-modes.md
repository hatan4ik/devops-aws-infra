# Failure-mode and recovery inventory

The table names response objectives as validation targets, not delivered SLOs.
Exact alarms, owners, and thresholds are protected environment inputs.

| Failure mode | Detection | Containment / recovery | Evidence before closure | Owner |
|---|---|---|---|---|
| Regional API impairment | ALB, synthetic, application latency/error SLOs | Controlled Global Accelerator traffic shift; use the [failover runbook](../runbooks/regional-failover.md) | Incident timeline, client/API/AuthZ tests, capacity and data health | SRE + service owner |
| Cognito primary/secondary limitation | Login journey synthetics, Cognito metrics, provider support status | Follow supported Cognito flow; do not claim MRR write failover before ADR 0011 is resolved | Login result, quota, documented product limitation | Identity owner |
| DynamoDB replication/data inconsistency | Replication, conditional-write, application integrity checks | Stop unsafe writes; use approved data recovery rather than traffic-only failover | Replication/data consistency evidence and recovery approval | Data owner |
| TGW/VPN/BGP path loss | Tunnel/BGP health, route and Flow Logs | Withdraw invalid routes; use redundant tunnel/path; follow hybrid onboarding rollback | Prefix, tunnel, route-table, and connectivity evidence | Network owner |
| KMS/Secrets/endpoint denial | Application errors, IAM/KMS/endpoint logs | Roll back policy/config change; restore least-privilege access only | CloudTrail, policy diff, service recovery test | Security + platform owner |
| Terraform state corruption/concurrency | State error, unexpected plan, lock record, S3 version anomaly | Freeze Terraform and use the [state-restore runbook](../runbooks/state-restore.md) | Approved version/digests, refresh-only plan, CloudTrail | Platform/DevOps + Security |
| Central logging/evidence delivery failure | Delivery metrics, Config/Security Hub findings | Preserve local service logs; repair destination/policy through approved change | Restored delivery, retention/immutability proof | Security + SRE |
| Cost/usage surge | Budgets, anomaly detection, service usage | Throttle/scale only with service-owner decision; retain user/security requirements | Cost Explorer/CUR, decision record, customer impact | FinOps + service owner |

No automatic remediation or automated fault injection is authorized by this
repository. Each response remains change-controlled under ADR 0013.
