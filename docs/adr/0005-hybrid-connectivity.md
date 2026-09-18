# ADR 0005: Use dual Site-to-Site VPN with BGP; defer Direct Connect

**Status:** Accepted — Phase 3 stakeholder approval recorded 2026-09-18.  
**Decision date:** 2026-09-18

## Context

The platform needs encrypted, redundant on-premises connectivity in multiple Regions. No enterprise ASN, CIDRs, devices, bandwidth, or latency target has been supplied. The local reference validates hub-and-spoke, encrypted VPN, BGP, dual paths, and a private-circuit upgrade pattern; it is Azure-specific and must not dictate the AWS product choice.

## Options considered

1. A single Site-to-Site VPN connection per Region with static routes.
2. Two dedicated Direct Connect ports per Region from the initial deployment.
3. Two independent customer-gateway endpoints and two Site-to-Site VPN connections per Region, each IPsec/IKEv2 plus eBGP, terminating on the regional TGW; Direct Connect as a measured upgrade.

## Quorum review

| Reviewer | Position and owned concern |
|---|---|
| Cloud Architect | **Approve 3.** It is AWS-native, resilient, and does not assume DX demand before measurements. |
| Network Engineer | **Approve 3.** BGP provides controlled propagation and failover; ASN/prefix governance is a precondition. |
| Security Engineer | **Approve 3.** VPN encryption, prefix filtering, and no transitive production access are enforceable. |
| SRE | **Dissent: prefer 2.** A private circuit offers more predictable latency/jitter for critical on-premises paths. |
| Platform/DevOps Lead | **Approve 3.** It has lower initial fixed cost and a clear Terraform/test contract. |

**Result:** 4–1 for option 3.

## Decision

Use two independent customer-gateway devices/public endpoints and two VPN connections to each regional TGW. Each AWS VPN connection provides its own redundant tunnels. Use route-based IPsec/IKEv2 and eBGP; assign unique private BGP ASNs, tunnel CIDRs, and maximum prefix limits from an approved allocation. Advertise only summarized approved prefixes and prefer local-region paths; failover routes are less-preferred through BGP policy.

Direct Connect is a later change only when VPN cannot meet demonstrated bandwidth, latency/jitter, or availability requirements. The evaluation must compare two diverse Direct Connect paths (about $438/month for two 1-Gbps dedicated AWS ports before provider/cross-connect/data charges) against four regional VPN connection/TGW attachment pairs (about $292/month before data/public IPv4).

## Consequences

- On-premises equipment and routing ownership are blocking external inputs; no CIDR/ASN is invented in Terraform.
- Tunnel-state, BGP-route, prefix-count, and packet-loss alerts feed the Network SRE runbook; failover is game-day tested.
- Options 1 and 2 are rejected: static/single VPN is not resilient enough, and initial DX carries a higher fixed commitment without evidence that it is needed.
