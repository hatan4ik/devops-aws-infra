# SRE, observability, and recovery

## SLOs and alerts

| Service | SLI / target | Page condition | Owner |
|---|---|---|---|
| API | Availability 99.99%; regional service latency p50 <=100 ms, p99 <=250 ms. | Regional 5xx, saturation, or p99 breach consumes error budget at the configured burn rate. | Workload SRE. |
| Authentication journey | Availability 99.9%; regional service latency p50 <=250 ms, p99 <=600 ms. | Cognito throttle/error, managed-login health, MRR replication, or token-validation failure. | Identity + SRE. |
| DynamoDB replication | MREC lag within the stated <=5-minute RPO target. | Replica degradation, replication lag, conditional-write conflict increase, or backup failure. | Workload SRE. |
| VPN/BGP | Both tunnels/paths healthy per Region. | One path degraded: ticket and investigation; both paths down: page. | Network SRE. |
| Security baseline | Zero unacknowledged HIGH Security Hub/Inspector findings after deployment. | New HIGH/CRITICAL, disabled trail/Config/GuardDuty, unauthorized public exposure. | Security operations. |

Latency SLOs exclude a user's ISP/mobile last-mile and third-party identity providers. They include platform edge, load balancer, app, authorization, and AWS service time. Synthetic clients run from each approved user geography after that geography is chosen.

## Telemetry architecture

- Workloads emit structured JSON application logs, metrics, and traces through ADOT/OpenTelemetry. Trace context crosses ALB, Fargate services, async events, and supported AWS SDK calls.
- CloudWatch Observability Access Manager shares read access from workload accounts to the dedicated Observability function in the Security/Audit account. The Log Archive account retains organization evidence independently.
- CloudTrail organization trail, Config snapshots/compliance, GuardDuty, Security Hub, Inspector, VPC Flow Logs, WAF logs, ALB access logs, Route 53 Resolver query logs, and VPN/TGW state changes are retained under the approved lifecycle policy.
- Alerts route by severity to Security and SRE on-call integrations. Any integration target, escalation schedule, and retention duration is an external prerequisite, not assumed here.

## Runbook minimums

| Runbook | Required evidence of completion |
|---|---|
| Regional API failover | Health signal, Global Accelerator endpoint state, capacity in survivor Region, API synthetic test, incident record, and controlled failback. |
| Cognito MRR failover | MRR replica status, Cognito custom-domain health routing, direct API/SDK regional routing, supported login test, documented primary-only feature limitation, and recovery test. |
| Hybrid connectivity outage | Both VPN tunnel/BGP state, prefix advertisements, TGW route-table state, Resolver lookup, customer-edge confirmation, and rollback/failover result. |
| Break-glass access | Approved incident ticket, MFA/identity evidence, temporary permission duration, CloudTrail review, credential/permission removal, and post-incident review. |
| Security finding | Finding ID, affected account/Region, containment, evidence preservation, remediation owner, SLA, and exception expiry if one is approved. |

The executable runbook sources are in [the runbook index](../runbooks/README.md). Their AWS checks are read-only and require explicit deployed identifiers; they do not establish that a live test has happened.

## Staging game day

Before production, execute the following in a sandbox/staging account with an approved change window:

1. Generate representative signed-in traffic in both Regions and record baseline SLOs.
2. Make one API Region unhealthy at the Global Accelerator/ALB health-check layer; prove traffic, autoscaling, DynamoDB behavior, trace continuity, and alerting in the survivor Region.
3. Exercise Cognito MRR supported authentication failover with a non-production user. Verify that signup/password/profile-write features are disabled or redirected according to the product contract.
4. Withdraw one BGP path and then both tunnels in one Region; assert route propagation/withdrawal, prefix filters, DNS resolution, and no unintended production/non-production reachability.
5. Restore all paths, verify convergence and replication health, collect evidence, and update the ADR/runbook with measured RTO/RPO.

No production region-failover claim is valid until this game day passes with the chosen Regions, current service quotas, workload build, and on-premises devices.
