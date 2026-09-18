# Phase 4: Repository and Code Strategy

## Repository List

Following the Hybrid Monorepo strategy (see [ADR-0009](../adr/0009-repository-strategy.md)), here is the proposed repository layout under the target GitHub Organization. 

*(Assume organization prefix: `ses-`)*

### 1. Root / Platform Repositories
* **`ses-aws-platform-roots`**: The primary monorepo containing all environment-specific root instantiations, separated by layer.
  * `/org` (Control Tower / Organizations / SCPs)
  * `/network` (TGW Hub, VPN, IPAM)
  * `/security` (GuardDuty, Security Hub, Macie)
  * `/identity` (IAM Identity Center, Cognito User Pools)
  * `/workload-auth` (Fargate clusters, DynamoDB, CloudFront for the Auth API)
  * `/workload-app` (Fargate clusters, ElastiCache, CloudFront for the core API)
* **`ses-aws-platform-docs`**: Architecture, ADRs, runbooks, and game-day plans. *(Note: This is effectively the current repository we are working in, which will be renamed or migrated).*
* **`ses-terraform-pipelines`**: Reusable GitHub Actions workflows (`workflow_call`) to enforce standard CI/CD steps (fmt, validate, tflint, checkov, plan, apply) across all other repos.

### 2. Independent Module Repositories
These modules have independent lifecycles, strict semantic versioning, and are consumed by the roots.
* **`terraform-aws-tgw-hub`**: Manages Transit Gateway, Route Tables, and inter-region peering.
* **`terraform-aws-vpc-workload`**: Standardized spoke VPC with isolated subnets, NAT, and VPC Endpoints.
* **`terraform-aws-ecs-fargate`**: Standardized ECS cluster, task definitions, and ALB integration.
* **`terraform-aws-cognito-userpool`**: Cognito User Pool with custom Lambda triggers for multi-region sync.
* **`terraform-aws-dynamodb-global`**: Multi-region Active-Active DynamoDB configuration.

---

## Governance and Branch Protection

The following governance rules are enforced globally via GitHub settings (ideally managed by a `terraform-github` provider in the `ses-aws-platform-roots/org` layer):

### 1. Branch Protection (`main` branch)
* **Require signed commits**: All commits must be GPG/SSH signed.
* **Require pull request reviews**: Minimum 2 approvals.
* **Require review from Code Owners**: Modifications to specific layers require domain-owner approval.
* **Require status checks to pass before merging**:
  * `Terraform Format`
  * `TFLint`
  * `Checkov (Security)`
  * `Terraform Plan (No Errors)`
  * `Terraform Test`
* **Do not allow bypassing the above settings.**

### 2. CODEOWNERS (`.github/CODEOWNERS`)
Inside the `ses-aws-platform-roots` monorepo, ownership is granularly delegated:
```text
# Global default
* @ses-platform-engineering

# Network layer requires Network Engineers
/network/ @ses-network-engineering

# Security layer requires Security Engineers
/security/ @ses-security-engineering

# Identity layer requires IAM experts
/identity/ @ses-identity-engineering
```

### 3. Release Lifecycle (Semantic Versioning)
For independent module repositories (`terraform-aws-*`):
* Merges to `main` trigger an automated GitHub Release.
* Tags follow SemVer (`v1.0.0`).
* Root repositories must pin module references to a specific SemVer tag:
  `source = "git::https://github.com/ses/terraform-aws-vpc-workload.git?ref=v1.2.0"`

