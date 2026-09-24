# Platform roadmap

The repository currently operates a private single-account sandbox. The target
remains an AWS-native, multi-account, multi-Region platform for low-latency
applications and large authenticated user populations. This is a sequence of
approval gates, not executable Terraform source.

## Current baseline

- GitHub OIDC delivery identity, encrypted isolated Terraform state, and
  root-specific plan/apply/drift workflows.
- A private `10.64.0.0/16` sandbox VPC, two private subnets, Flow Logs, and
  required private AWS endpoints.
- Private ECS/ECR/Cognito/KMS/DynamoDB platform dependencies and the
  `auth-demo` Fargate service.

## Next controlled stages

1. **Service-module migration.** Release a signed `aws.modules.ecs-service`
   v1 tag, migrate the sandbox workload with Terraform `moved` blocks, review
   a no-replacement plan, and deploy only through the workload workflow.
2. **Public application decision.** Approve a domain owner, DNS, ACM, WAF,
   ingress, OAuth callback URLs, application SLOs, and rollback design before
   exposing an application publicly.
3. **Account model.** Approve owners, email addresses, OU placement, logging,
   security access, and budget for Network, Security/Audit, Log Archive,
   Shared Services, and workload accounts. Use a reviewed Organizations plan;
   do not infer values or create accounts manually.
4. **Network foundation.** Approve an enterprise IPAM supernet, non-overlapping
   Region CIDRs, route domains, Regional TGW ASNs, and a route-leak matrix.
   Then implement and review the Network-account TGW, RAM sharing, workload
   attachments, and explicit routing as new active roots.
5. **Hybrid connectivity.** Obtain on-premises ASNs, two customer-gateway IPs
   per Region, accepted prefixes, tunnel ownership, and monitoring. Deploy
   Site-to-Site VPN/BGP only after the Network foundation exists.
6. **Second Region and production.** Validate latency, quotas, data residency,
   Cognito capability, replication/data recovery, capacity, observability,
   game-day evidence, and cost acceptance before a second Region or production
   workload is created.

Every stage requires a decision record where the architecture changes, a new
root-specific OIDC role/workflow where the delivery boundary changes, a
reviewed plan, protected apply, and post-apply drift evidence.
