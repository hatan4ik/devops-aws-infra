# ADR 0002: Multi-Region Availability Strategy

## Status
Accepted

## Context
The application serves millions of users with latency targets (p99 < 300ms auth, < 200ms API) and strict availability (99.99%) and RTO (< 15 mins).

## Options Considered
1. **Active-Active**: Traffic is served simultaneously from multiple regions via latency-based routing.
2. **Active-Passive (Warm Standby)**: Primary region serves all traffic; secondary region has scaled-down infrastructure and replicated data.
3. **Active-Passive (Pilot Light)**: Secondary region only has data replication and core network; compute is provisioned on failover.

## Decision
**Active-Active Multi-Region**

We will utilize Route 53 Latency-Based Routing to direct users to the closest region. State will be replicated using DynamoDB Global Tables.

## Consequences
* **Positive**: Meets the aggressive p99 latency targets by serving users globally. RTO is near-zero for region failure since traffic just shifts.
* **Negative**: Complex data conflict resolution; increased cost due to running full production capacity in multiple regions; CI/CD pipeline complexity.

## Dissenting Opinions
* *Cloud Architect*: Active-Active introduces significant state replication challenges and doubles base compute costs.
* *Resolution*: The Platform Lead and SRE insisted that < 15 minute RTO and strict latency bounds at the edge cannot be reliably met without Active-Active. DynamoDB Global Tables handles the replication pain natively.
