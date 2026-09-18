# Phase 3: Target Architecture Summary

## Overview
This document summarizes the target state architecture, estimated costs, and required external verifications for the multi-region, multi-account AWS platform. The architecture is detailed in the accompanying Architecture Decision Records (`docs/adr/`).

## Architectural Decisions (ADRs)
* **[ADR 0001: Account Structure](file:///Users/nathanels/devops-aws-infra/docs/adr/0001-account-structure.md)**: Custom AWS Organizations + SCPs via Terraform (over Control Tower).
* **[ADR 0002: Multi-Region](file:///Users/nathanels/devops-aws-infra/docs/adr/0002-multi-region-strategy.md)**: Active-Active with Route 53 Latency Routing and DynamoDB Global Tables.
* **[ADR 0003: Compute](file:///Users/nathanels/devops-aws-infra/docs/adr/0003-compute-platform.md)**: Amazon ECS on Fargate.
* **[ADR 0004: Identity](file:///Users/nathanels/devops-aws-infra/docs/adr/0004-identity-provider.md)**: Amazon Cognito User Pools.
* **[ADR 0005: Egress Inspection](file:///Users/nathanels/devops-aws-infra/docs/adr/0005-egress-inspection.md)**: Decentralized NAT Gateways + VPC Endpoints + Route 53 DNS Firewall (avoiding AWS Network Firewall costs).
* **[ADR 0006: Edge](file:///Users/nathanels/devops-aws-infra/docs/adr/0006-edge-ingress.md)**: CloudFront + AWS WAF + ALB.
* **[ADR 0007: Authorization](file:///Users/nathanels/devops-aws-infra/docs/adr/0007-fine-grained-auth.md)**: Amazon Verified Permissions.
* **[ADR 0008: Observability](file:///Users/nathanels/devops-aws-infra/docs/adr/0008-observability.md)**: Centralized CloudWatch Cross-Account Observability.

## Base Cost Estimate (Per Environment / Per Region)
*Note: This is a baseline structural cost, excluding variable traffic/compute scale.*
* **Transit Gateway**: ~$36.50/month per attachment + $0.02/GB processed.
* **NAT Gateways**: 3x AZs = ~$98.55/month fixed + $0.045/GB processed. (Saved ~$850/mo by rejecting Network Firewall).
* **VPC Endpoints (PrivateLink)**: ~$7.30/month per endpoint per AZ. Assuming 5 core endpoints (S3, ECR API, ECR DKR, Logs, KMS) across 3 AZs = ~$109.50/month.
* **AWS Shield Advanced**: $3,000/month (Consolidated billing across org, so only paid once for Prod). *Note: Optional for Dev/Staging.*
* **Cognito**: 5M MAU * $0.0055 (volume tier) = ~$27,500/month for Prod (variable based on active logins). Dev/Staging practically free.

## Items Requiring External Verification (Blockers)
Before proceeding to implementation, the following must be verified out-of-band:
1. **AWS Support Quotas**: Request an increase for Amazon Cognito API limits. The default limits cannot support 5,000 RPS.
2. **On-Premise Networking**: Verify the on-premise ASN (Autonomous System Number) and ensure the BGP CIDR ranges do not conflict with the proposed AWS IPAM ranges.
3. **Identity Sync**: Verify if an external corporate IdP (e.g., Azure AD from the CCoE setup) needs to be federated into Cognito via SAML/OIDC for internal admins.

## Next Steps
Awaiting approval of Phase 3 design decisions before moving to **Phase 4 (Repository and code strategy)**.

