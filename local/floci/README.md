# Local Floci integration catalog

This is the repository's **local-only** integration catalog. It exercises the
same immutable `aws.modules.*` releases used by platform work without sharing
state, credentials, variables, or execution paths with `infra/active`.

It is not a replacement for AWS. In particular, it does not certify Control
Tower, Organizations/SCP enforcement, IAM Identity Center, multi-account RAM,
Transit Gateway, VPN/BGP, public Route 53, ACM public validation, CloudFront,
or WAF as working production controls. See
[compatibility-matrix.md](compatibility-matrix.md) for the current boundary.

## Safety boundary

All Terraform commands use `bin/tf-local.sh`. It sources
`tools/floci/env.sh`, uses dummy credentials, and refuses any endpoint other
than `http://localhost:4566` or `http://127.0.0.1:4566`. Do not run Terraform
directly from these directories.

Local state and provider downloads are ignored. They never belong in Git and
are never copied to AWS state.

## Quick start

From this directory:

```bash
make up
make smoke
make init STACK=foundation
make validate STACK=foundation
make plan STACK=foundation
```

`foundation` is the only stack intended for a local apply. It composes a
private VPC, ECS platform, private endpoints, ECR, DynamoDB session store,
Cognito pool/client, and an artifact S3 bucket from immutable module commits.
Its deliberately local lifecycle overrides make cleanup possible; they must
not be copied to production.

Floci 2.2.0 does not implement VPC Encryption Control, rejects this ECR
lifecycle-policy encoding, and cannot converge VPC Flow Logs. The local
fixture excludes VPC Encryption Control and flow logs and uses the released
ECS registry submodule with no lifecycle policy; the production module defaults
are not changed. The exact boundary is kept in the compatibility matrix.

```bash
make apply STACK=foundation
make destroy STACK=foundation
```

The blueprint stacks are currently interface-contract validation only:

```bash
make contract
./bin/tf-local.sh governance-contracts init -backend=false
./bin/tf-local.sh governance-contracts validate
```

To remove local emulator data after all local Terraform stacks are destroyed:

```bash
make reset
```

`make reset` deletes only Docker Compose's named `floci-local-data` volume; it
does not access AWS.

## Stack ownership

| Directory | Purpose | Remote effect allowed |
| --- | --- | --- |
| `foundation/` | Floci-compatible private-network/platform/identity/storage integration candidate | Local emulator only |
| `private-application/` | Digest-pinned private Fargate blueprint interface | Terraform validation only |
| `edge-web/` | CloudFront/S3/WAF/ACM/Route 53 edge blueprint interface | Terraform validation only |
| `governance-contracts/` | Local guardrails that make the emulator boundary explicit | Terraform validation only |

## Naming and tags

Every resource-owning stack calls the signed
[`aws.modules.naming` v1.0.1](https://github.com/hatan4ik/aws.modules.naming)
release tag `v1.0.1`. Names are never assembled from a free-form prefix in a
resource call.

| Stack | Canonical names it derives |
| --- | --- |
| `foundation/` | `sandbox-floci-network`, `sandbox-floci-platform`, `sandbox-floci-identity`, `sandbox-floci-platform-application`, `sandbox-floci-artifacts-<local-account-id>` |
| `private-application/` | `sandbox-floci-orders`, with references to the derived platform and registry names |
| `edge-web/` | `sandbox-floci-web`, `sandbox-floci-web-assets-<local-account-id>`, and `sandbox-floci-web-logs-<local-account-id>` |

The naming module allows only its canonical environments; `sandbox` is the
non-production class here. Every local resource also receives
`DeploymentScope=local` and `Emulator=floci`, so an emulator resource is never
mistaken for an AWS sandbox resource. `Repository`, `Root`, `Environment`, and
`ManagedBy=terraform` come directly from the naming module.

## Configuration

Every stack has a committed `terraform.tfvars.example`. It documents local
inputs and optional allocation tags without placing real account IDs, names,
hosted zones, certificates, or secrets in version control. Copy it to
`terraform.tfvars` only for an intentionally local variation; names themselves
are derived by the naming module.

For the real platform, use the environment-specific roots under
`infra/active/roots`, their approved variable files, GitHub OIDC, reviewed
plans, and AWS post-apply checks. Do not repoint this catalog at an AWS
endpoint.
