# Sandbox private workload root

This root owns private ECS Fargate application services for the existing
`sandbox-platform-dev` cluster. It has an independent remote-state key and is
the only approved delivery lane for app task definitions, services, roles,
service security groups, autoscaling, per-service logs, and optional Cognito
app clients.

It deliberately begins with `applications = {}`. That is a safe, deployable
empty workload state: it creates no task, service, public endpoint, or OAuth
client. Add an application only through a reviewed pull request using an
immutable ECR image digest and typed `applications` value in `terraform.tfvars`.

The root discovers the VPC, two private subnets, ECS cluster, KMS data key, and
session table through scoped AWS data sources. It does not read another
Terraform state file.

## Required app contract

Before adding a service, provide its ECR image digest, CPU/memory, port and
health check, desired/min/max task counts, non-secret configuration, secret
ARNs, required task-policy statements, and whether it uses the session table.
For a Cognito OAuth client, also supply the user-pool ID, HTTPS callback/logout
URLs, and approved scopes. Public ingress, DNS, ACM, WAF, and load balancing
are intentionally separate delivery decisions.
