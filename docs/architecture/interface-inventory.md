# Interface inventory and contracts

This inventory defines boundary ownership before implementation. Identifiers,
CIDRs, ARNs, domains, certificates, and endpoints remain protected deployment
inputs; they are not inferred from this source tree.

| Interface | Producer / owner | Consumer | Contract and security boundary | Failure owner / evidence |
|---|---|---|---|---|
| Public web delivery | Edge account: CloudFront + WAF | Browsers | HTTPS/TLS, WAF policy, cache policy, approved DNS/certificate | Edge owner; WAF/CloudFront logs and synthetics |
| Dynamic API | Regional workload account: Global Accelerator/ALB | Browsers and approved clients | HTTPS, WAF, authenticated JWT/API contract, private ECS targets | Service owner; ALB/WAF/app telemetry |
| Authentication | Identity account: Cognito | Web/API clients and application services | OIDC/OAuth scopes, signed JWT validation, MFA/abuse controls | Identity owner; Cognito metrics and login synthetics |
| Authorization | Application policy point / Verified Permissions where approved | API services | Explicit allow/deny decision contract, audited policy version, no implicit cross-tenant access | Application security owner; decision/audit evidence |
| Workload-to-AWS services | Workload VPC endpoints | ECS tasks | PrivateLink/gateway endpoints, IAM roles, TLS, endpoint policy | Platform/network owner; Flow Logs and IAM evidence |
| Cross-account platform services | Shared services / Log Archive / Security accounts | Workload and platform accounts | AWS RAM/resource policies, least-privilege roles, KMS grants, CloudTrail | Platform/security owner; policy review and CloudTrail |
| Regional network transit | Network account TGW | Workload/shared/on-prem VPCs | Route-table segmentation, appliance/inspection policy, explicit prefixes | Network owner; route export and Flow Logs |
| On-premises connectivity | Network account VPN/TGW | Approved on-premises routing domains | Dual IPsec tunnels, BGP, prefix filters, encrypted transport | Network owner; tunnel/BGP health and route tests |
| Terraform state access | Shared services state backend | Approved CI and break-glass roles | S3/KMS/DynamoDB least privilege, short-lived credentials, no standing local profiles | Platform/Security; state backup, lock and CloudTrail evidence |

Any new interface requires its owner, authentication/authorization method,
data classification, encryption path, timeout/retry behaviour, quota, test, and
failure-mode entry before it is used in a plan.
