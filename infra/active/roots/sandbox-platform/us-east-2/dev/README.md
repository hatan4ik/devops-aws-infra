# Sandbox platform-core root

This root creates the reusable private application foundation in the sandbox
VPC: interface/gateway endpoints, endpoint security group, immutable scanned
ECR repository, enhanced-observability ECS cluster, KMS data key/alias,
encrypted CloudWatch log group, protected DynamoDB session table, and Cognito
user pool.

It intentionally does **not** create a task definition, ECS service, load
balancer, public route, customer domain, OAuth client, second Region, transit
gateway, or VPN. Application runtime belongs to the independent
[`sandbox-workload`](../../sandbox-workload/us-east-2/dev/README.md) root so
that image/service changes have their own state, plan, role policy, and
approval record.

The root now includes the private Cognito IDP endpoint required by a future
no-NAT private service that validates Cognito tokens or calls Cognito APIs.
