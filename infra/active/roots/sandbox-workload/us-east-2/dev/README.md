# Sandbox private workload root

This root owns private ECS Fargate application services for the existing
`sandbox-platform-dev` cluster. It has an independent remote-state key and is
the only approved delivery lane for app task definitions, services, roles,
service security groups, autoscaling, per-service logs, and optional Cognito
app clients.

The first reviewed service is `auth-demo`: two private Fargate tasks running an
immutable ECR digest, with CPU target tracking from two to twelve tasks. It
creates a Cognito authorization-code client for the documented local HTTPS
callback only; it does not add public ingress, a hosted application, or a
customer authentication journey.

The reviewed service composition requests one Terraform-managed fresh ECS
deployment after the private task-egress ordering fix. It remains private and
does not introduce NAT, an internet gateway, or public task IPs.

The root discovers the VPC, two private subnets, ECS cluster, KMS data key, and
session table through scoped AWS data sources. It reads only the non-secret
platform output state to obtain the existing Cognito user-pool ID; its delivery
policies permit read-only access to that one state prefix.

## Required app contract

Before adding a service, provide its ECR image digest, CPU/memory, port and
health check, desired/min/max task counts, non-secret configuration, secret
ARNs, required task-policy statements, and whether it uses the session table.
For a Cognito OAuth client, also supply HTTPS callback/logout URLs and approved
scopes. The root derives the user-pool ID from the platform output rather than
duplicating it in tfvars. Public ingress, DNS, ACM, WAF, and load balancing are
intentionally separate delivery decisions.
