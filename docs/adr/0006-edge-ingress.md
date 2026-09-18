# ADR 0006: Edge and Ingress Routing

## Status
Accepted

## Context
We need to ingest user traffic efficiently, securely, and route it to the closest Active-Active region.

## Options Considered
1. **CloudFront + WAF + ALB**: Standard HTTP/S edge termination.
2. **AWS Global Accelerator + ALB**: Anycast IP routing at the TCP/UDP layer.
3. **Route 53 latency routing direct to ALB**: DNS-based routing.

## Decision
**CloudFront + AWS WAF + ALB**

Traffic will ingress via CloudFront to leverage AWS Edge caching, DDOS protection (Shield), and WAF. CloudFront origin groups will handle primary/secondary region failovers.

## Consequences
* **Positive**: AWS WAF integrates natively. Static assets are cached at the edge. Terminating TLS at edge reduces backend CPU.
* **Negative**: CloudFront is L7 only (HTTP/S). If we need raw TCP (e.g. MQTT/WebSockets), we would need Global Accelerator.

## Dissenting Opinions
* *Network Engineer*: Global Accelerator provides faster failover (BGP Anycast vs DNS TTL) and lower jitter.
* *Resolution*: CloudFront Origin Groups provide acceptable HTTP failover without the large fixed cost ($18/mo + premium bandwidth) of Global Accelerator. We will use CloudFront.
