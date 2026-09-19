# ADR 0005: Egress Traffic Inspection

## Status
Superseded by [ADR 0014](0014-canonical-architecture-and-iac-boundary.md)

> Historical record only. The active ingress and egress decision is
> [ADR 0004](0004-edge-ingress-and-egress.md).

## Context
Security baseline requires strict control over outbound traffic. We need to decide if we route all egress through a centralized inspection layer.

## Options Considered
1. **AWS Network Firewall in Centralized Inspection VPC**: All egress from workload VPCs goes via Transit Gateway to an Inspection VPC.
2. **Decentralized NAT Gateways**: Egress directly via NAT Gateway in each workload VPC.
3. **Squid/Proxy fleet on EC2**: Self-managed proxies.

## Decision
**Decentralized NAT Gateways + VPC Endpoints (No Central Network Firewall initially)**

We will use NAT Gateways per AZ in the workload VPCs, heavily combined with VPC Endpoints (PrivateLink) to ensure AWS service traffic never hits the NAT. Egress domains will be restricted via Security Group outbound rules and DNS Firewall.

## Consequences
* **Positive**: Saves ~$285/month per NAT per AZ per Region + TGW processing fees + Network Firewall base costs (~$285/mo per AZ). Avoids centralized bottleneck.
* **Negative**: Lacks deep packet inspection (IDS/IPS) for outbound internet traffic.

## Dissenting Opinions
* *Security Engineer*: Demanded AWS Network Firewall for L7 egress filtering.
* *Resolution*: The Cloud Architect and Platform Lead overrode this due to the "financially conservative" constraint. VPC Endpoints cover 90% of traffic. We will implement Route 53 DNS Firewall (cost-effective) to block malicious domains instead of full DPI.
