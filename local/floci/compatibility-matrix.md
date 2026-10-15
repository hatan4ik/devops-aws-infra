# Floci compatibility matrix

This matrix is intentionally conservative. **Supported** below means this
repository has a recorded local Terraform apply/destroy result; it does not
mean AWS feature parity. Every real account, organization, networking, and
production deployment decision still goes through the GitOps roots under
`infra/active` and a reviewed AWS plan.

| Scope | Module/release pin | Local treatment | Why |
| --- | --- | --- | --- |
| AWS identity, SQS, basic ECS control plane | Floci smoke scripts | Supported smoke | Recorded against local Floci only; it proves endpoint routing and Docker-backed ECS control-plane behaviour. |
| Private VPC, platform ECS, ECR, DynamoDB, Cognito, S3 | `aws.modules.vpc` v1.1.1, `ecs` v1.0.0, `cognito` v2.0.0, `s3` v1.0.2 | Local apply with exceptions | `foundation/` applies the core resources locally. Floci 2.2.0 does not implement VPC Encryption Control, rejects this ECR lifecycle-policy encoding, and cannot keep VPC Flow Logs converged because it omits log-group attributes. The local fixture disables the first and flow logs, and calls the released ECS registry submodule directly with no lifecycle policy for the second. Production retains module defaults and needs AWS proof. |
| Private microservice composition | `aws.modules.blueprint-microservice-private` v2.0.0 | Contract validation | It combines ALB, Fargate, image pulls and endpoint policy enforcement. Local validation guards its interface; the matrix will be upgraded only after a repeatable apply/destroy proof. |
| Edge/static web composition | `aws.modules.blueprint-edge-web-app` v1.0.1 | Contract validation | CloudFront, us-east-1 ACM validation, public Route 53, WAF and global delivery need AWS evidence. |
| Organizations, IAM Identity Center, SCPs | AWS-native governance controls | Out of emulator scope | API availability is not equivalent to organization enforcement or delegated-admin behaviour. |
| TGW, RAM sharing, site-to-site VPN, BGP | `aws.modules.tgw` plus AWS networking | Out of emulator scope | These need actual multi-account/multi-network route propagation and on-prem peer evidence. |

## Test promotion rule

1. Module repository unit/contract tests run first.
2. This catalog proves safe local control-plane behaviour where noted.
3. The sandbox GitOps roots produce a reviewed AWS plan.
4. Only an approved AWS apply and post-apply checks promote a capability to the
   real environment. Local state is never copied to or from AWS state.
