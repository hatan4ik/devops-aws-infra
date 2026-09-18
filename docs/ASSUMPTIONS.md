# Architecture Assumptions

## 1. Scale and Performance
* **User Base:** 5,000,000 registered users.
* **Concurrency:** 5% peak concurrency (250,000 concurrent active users).
* **Auth RPS:** 5,000 requests per second (RPS) at peak.
* **Application API RPS:** 25,000 requests per second (RPS) at peak.
* **Latency Target (Auth):** p50 < 100ms, p99 < 300ms per region.
* **Latency Target (API):** p50 < 50ms, p99 < 200ms per region.

## 2. Availability and Resiliency
* **Target Availability:** 99.99% (approx. 4.38 minutes downtime/month).
* **RTO (Recovery Time Objective):** < 15 minutes for regional failover.
* **RPO (Recovery Point Objective):** < 5 minutes for session/transaction data.

## 3. Data Residency & Compliance
* **Data Residency:** No strict single-country data residency requirements (multi-region replication is permissible). 
* **Compliance Scope:** Standard PII handling (SOC 2 / ISO 27001 baseline). No PCI-DSS or HIPAA requirements unless explicitly stated later.

## 4. Networking
* **On-Premise Infrastructure:** Exists and requires Site-to-Site VPN with BGP. Standard enterprise traffic.
* **Direct Connect:** Not required for Day 1; BGP over Site-to-Site VPN is sufficient for current bandwidth.
* **IPAM:** AWS IPAM will be used for CIDR allocation. No overlapping CIDRs with on-prem networks.

## 5. Financial / Budget
* **Budget Constraint:** Cost-conscious. Avoid large fixed-cost idle components where serverless/pay-as-you-go equivalents meet latency requirements.
