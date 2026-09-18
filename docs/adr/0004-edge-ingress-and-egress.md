# ADR 0004: Separate static edge delivery, dynamic API acceleration, and conditional egress inspection

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

The application needs secure low-latency public ingress while workload VPCs remain private. The design must also decide whether to pay for centralized egress inspection before there is a documented Internet dependency. Assumptions A-03, A-08, A-09, and A-15 apply.

## Options considered

1. Public ALBs with Route 53 latency records; NAT gateways in each workload VPC.
2. CloudFront-only origin failover for web and API; universal Network Firewall/NAT from day one.
3. CloudFront/WAF for static content, Global Accelerator to regional WAF-protected ALBs for dynamic API, and no workload Internet route; conditional centralized Network Firewall/NAT egress.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Dissent: prefer 2.** One CloudFront URL is simpler, but it does not make active-active dynamic origin selection as explicit. |
| Network Engineer | **Approve 3.** Anycast API ingress and ALB health endpoints provide predictable regional steering. |
| Security Engineer | **Approve 3.** Private tasks, WAF at each entry layer, and no default egress are the smallest attack surface. |
| SRE | **Approve 3.** Separate static/API failure modes and health checks make incident action clearer. |
| Platform/DevOps Lead | **Dissent: prefer 1.** It is cheaper, but has weaker global failover/traffic control. |

**Result:** 3–2 for option 3.

## Decision

CloudFront plus a global WAF delivers static content from private S3 origins. Dynamic API requests use Global Accelerator to two regional public ALBs; the public ALB subnets are the sole justified public subnets. ALB targets, Fargate tasks, databases, and caches are private. Shield Standard is enabled; Shield Advanced, WAF bot/fraud controls, and Global Accelerator remain finance-approved production costs.

Workload route tables have no Internet default route. AWS gateway/interface endpoints are used for supported AWS service dependencies. External Internet egress is denied until a workload exception is approved; that exception must use the centralized two-AZ Network Firewall + NAT service chain in the Network account and logs every path.

## Consequences

- Global Accelerator has an hourly and data-transfer charge, and regional WAF/ALB costs remain; the cost model makes these explicit.
- A workload requiring an unproxied public dependency becomes a security and cost review, not a security-group edit.
- Options 1 and 2 are rejected: distributed NAT creates avoidable exposure/cost; CloudFront-only origin failover does not satisfy the selected active-active dynamic API steering model, while universal firewall deployment pays a large fixed cost without an egress requirement.
