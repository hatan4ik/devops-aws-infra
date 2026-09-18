# Runbook: adding a Region

## Trigger and scope

Use for an approved additional AWS Region, not for the `region-a`/`region-b` source-layout names. Region selection must pass the residency, latency, service availability, quota, cost, and on-premises proximity review in assumptions A-07 and A-14.

## Preflight

1. Approve the concrete Region, account/OU scope, AZ count, IPAM pool/CIDR, route domain, primary/secondary data role, DNS/ACM ownership, and recovery objectives.
2. Revalidate AWS service availability and quotas for ECS/Fargate, ALB, Global Accelerator, CloudFront/WAF, Cognito tier/features, DynamoDB global tables, TGW, VPN, endpoints, KMS, CloudWatch, and security services in the chosen Region.
3. Approve the incremental cost estimate, including duplicated availability capacity, endpoints, TGW/VPN, data transfer, observability, and any Network Firewall/NAT/Shield/Direct Connect decision.
4. Confirm CIDR and ASN non-overlap with every AWS and on-premises routing domain. Approve DNS health checks, Global Accelerator endpoint behavior, failure thresholds, and maintenance window.
5. Resolve identity: Cognito MRR remains blocked by [ADR 0011](../adr/0011-cognito-mrr-provider-boundary.md). Do not claim authentication failover or deploy a manual replica until that ADR's provider-backed acceptance criteria are met.

## Controlled execution

1. Vend or verify the regional network and workload account baseline using the account-vending runbook.
2. Apply the network root through the protected pipeline: IPAM allocation, two-AZ private subnets, endpoint set, Flow Logs, regional TGW, explicit route tables, RAM shares, Resolver rules, and approved VPN/BGP attachments.
3. Apply regional workload composition through the protected pipeline. Add stateless capacity, regional data replica, health checks, WAF/ALB/Global Accelerator endpoint, metrics/log routing, KMS, and Secrets Manager only from approved inputs.
4. Add DNS/custom-domain routing only after certificates, health checks, data replication, and approved identity behavior are validated.
5. Run the read-only network/security/public synthetic checks and the staging game day before admitting production traffic.

## Acceptance evidence

- Approved plan/cost-diff, deployment-environment approval, OIDC CloudTrail sessions, serialized state-lock result, and reviewed apply output.
- IPAM allocation, TGW route-domain/peering evidence, endpoint/Flow Log evidence, two healthy VPN paths where hybrid connectivity applies, and negative cross-domain reachability test.
- DynamoDB/global data replica health, backup/restore test, log/trace centralization, SLO baseline from each approved synthetic geography, and capacity test showing survivor Region behavior.
- Identity and auth/API contract results. If MRR remains blocked, the release is not an identity multi-Region deployment and must use the explicitly approved interim product behavior.

## Abort and rollback

Do not shift user traffic when health checks, data replication, route isolation, or identity behavior is incomplete. Remove the new endpoint from traffic routing first; preserve logs and state; then use a separately reviewed Terraform change to reverse only the approved additions. Never delete a replicated data source or state backend as a routine rollback.
