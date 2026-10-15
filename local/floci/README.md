# Local Floci Integration Catalog & Developer Guide

This directory provides the repository's **local-only AWS development and integration catalog** powered by the [Floci AWS emulator](../../tools/floci/README.md).

It enables developers to rapidly test and iterate on Terraform module integrations, AWS CLI commands, and cloud-native blueprints entirely offline on their workstation without AWS credentials, remote state, or cloud expenditure.

---

## Table of Contents

1. [Safety Boundary & Blast Radius](#safety-boundary--blast-radius)
2. [Prerequisites](#prerequisites)
3. [Quick Start (5-Minute Onboarding)](#quick-start-5-minute-onboarding)
4. [Day-in-the-Life Developer Workflows](#day-in-the-life-developer-workflows)
   - [AWS CLI Integration](#1-aws-cli-integration)
   - [Floci AWS Web UI Console](#2-floci-aws-web-ui-console)
   - [Testing Terraform Stacks Locally](#3-testing-terraform-stacks-locally)
   - [Testing Module Changes Locally](#4-testing-module-changes-locally)
5. [Stack Ownership & Architecture](#stack-ownership--architecture)
6. [Naming Conventions & Tagging](#naming-conventions--tagging)
7. [Lifecycle: Stop, Reset & Cleanup](#lifecycle-stop-reset--cleanup)
8. [Troubleshooting & Diagnostics Playbook](#troubleshooting--diagnostics-playbook)

---

## Safety Boundary & Blast Radius

To guarantee that local testing never impacts or mutates real AWS infrastructure:

1. **Loopback-Only Wrapper (`bin/tf-local.sh`):**
   All Terraform invocations must go through `bin/tf-local.sh` (or `make`). The script explicitly verifies that `AWS_ENDPOINT_URL` resolves to `http://localhost:4566` or `http://127.0.0.1:4566` and will abort with an error if pointed anywhere else.
2. **Hermetic Credentials:**
   The environment uses dummy credentials (`AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test`). The STS identity resolves to the emulator's dummy account `000000000000`.
3. **Strict Root Separation:**
   Do **never** apply `infra/active/roots` against Floci. The active roots are production GitOps delivery roots with real remote-state backends and account dependencies.
4. **Isolated State:**
   Local Terraform state files (`.terraform`, `terraform.tfstate`) are gitignored and never synced to AWS S3/DynamoDB backends.
5. **Boundary Limitations:**
   Floci is an emulation layer for fast feedback. It does **not** simulate AWS Organizations/SCPs, Control Tower, IAM Identity Center, Transit Gateway, VPN/BGP, public Route 53, or ACM validation. Refer to the [Compatibility Matrix](compatibility-matrix.md) for supported vs out-of-scope services.

---

## Prerequisites

Before starting, ensure your workstation has:

- **Docker:** Docker Desktop or Colima running with `/var/run/docker.sock` accessible.
- **Docker Compose:** Compose v2 (`docker compose version`).
- **AWS CLI:** AWS CLI v2 (`aws --version`).
- **Terraform:** Terraform >= 1.9 or OpenTofu.
- **Make:** GNU Make and Bash (`set -euo pipefail`).
- **curl:** Standard command-line HTTP client.

---

## Quick Start (5-Minute Onboarding)

All routine tasks are automated via the `Makefile` in this directory:

```bash
cd local/floci

# 1. Start the Floci emulator in the background
make up

# 2. Check container status
make status

# 3. Verify region configuration (asserts us-east-2 across core and web UI)
make verify-region

# 4. Run the end-to-end smoke test (validates STS, SQS, and ECS cluster)
make smoke

# 5. Initialize, validate, and plan the local foundation stack
make init STACK=foundation
make validate STACK=foundation
make plan STACK=foundation
```

To see all available targets at any time:
```bash
make help
```

---

## Day-in-the-Life Developer Workflows

### 1. AWS CLI Integration

You can interact directly with the emulator using standard AWS CLI commands without specifying `--endpoint-url` on every invocation.

First, source the environment exports:

```bash
# From local/floci directory:
source ../../tools/floci/env.sh

# Or from the repository root:
source tools/floci/env.sh
```

This exports:
- `AWS_ENDPOINT_URL=http://localhost:4566`
- `AWS_REGION=us-east-2` & `AWS_DEFAULT_REGION=us-east-2`
- `FLOCI_DEFAULT_REGION=us-east-2`
- `FLOCI_DEFAULT_AVAILABILITY_ZONE=us-east-2a`
- `AWS_ACCESS_KEY_ID=test` & `AWS_SECRET_ACCESS_KEY=test`

Now run standard AWS CLI commands against Floci:

```bash
# Verify STS returns the local account 000000000000
aws sts get-caller-identity

# Work with S3
aws s3 mb s3://my-dev-bucket
aws s3 ls
aws s3 cp myfile.txt s3://my-dev-bucket/
aws s3 rm s3://my-dev-bucket/myfile.txt
aws s3 rb s3://my-dev-bucket

# Work with SQS
aws sqs create-queue --queue-name local-orders-queue
aws sqs list-queues
aws sqs send-message \
  --queue-url http://localhost:4566/000000000000/local-orders-queue \
  --message-body '{"orderId":"123","status":"pending"}'
aws sqs receive-message \
  --queue-url http://localhost:4566/000000000000/local-orders-queue

# Work with ECS
aws ecs list-clusters
```

---

### 2. Floci AWS Web UI Console

Floci features a built-in web management console for inspecting local AWS resources visually:

1. **Open the Core Emulator Landing Page:**
   Navigate in your browser to:
   ```text
   http://localhost:4566/
   ```
2. **Launch the AWS Web UI Console:**
   Click the **"Open UI"** button (or navigate to `http://localhost:4566/_floci/ui`).
   - Floci dynamically spins up the `floci-aws-ui` sidecar container on port `4500` via the mounted Docker socket.
   - The UI launches connected to Floci core and is automatically pinned to `AWS_REGION=us-east-2`.
3. **Direct UI Access:**
   Once spawned, the console is accessible directly at:
   ```text
   http://localhost:4500/
   ```
4. **Visual Inspection:**
   Browse created SQS queues, DynamoDB tables, ECS clusters, and S3 buckets directly from the browser interface.

---

### 3. Testing Terraform Stacks Locally

The `local/floci` directory contains local fixtures configured with immutable module pins:

```bash
# 1. Initialize local stack (downloads modules and providers without remote backend)
make init STACK=foundation

# 2. Syntax and schema validation
make validate STACK=foundation

# 3. Execution plan against local emulator
make plan STACK=foundation

# 4. Apply the stack locally
make apply STACK=foundation

# 5. Destroy the local stack when testing completes
make destroy STACK=foundation
```

#### Blueprint Contract Testing

The blueprint stacks (`private-application` and `edge-web`) validate architecture module contracts:

```bash
make contract
```
This initializes and validates both blueprints to ensure no schema drift or interface breakage occurred.

---

### 4. Testing Module Changes Locally

When developing updates to an external module (e.g. `aws.modules.vpc`, `aws.modules.ecs`, or `aws.modules.naming`):

1. **Override Module Source for Local Testing:**
   In `local/floci/foundation/main.tf`, temporarily point the module `source` parameter to your local checkout or branch tag:
   ```hcl
   module "network" {
     # Local development override:
     source = "../../../../aws.modules.vpc"
     # ...
   }
   ```
2. **Re-initialize and Plan:**
   ```bash
   make init STACK=foundation
   make plan STACK=foundation
   ```
3. **Apply & Verify:**
   ```bash
   make apply STACK=foundation
   make verify-region
   ```
4. **Inspect Resources:**
   Use the AWS CLI or the Web UI console (`http://localhost:4500`) to confirm that resource attributes, routes, and tags conform to requirements.
5. **Revert Temporary Module Source:**
   Once verified, commit the changes in the module repository, release a tagged commit, and update the immutable Git source pin in `foundation/main.tf`.

---

## Stack Ownership & Architecture

| Directory | Scope & Purpose | Execution Mode |
| :--- | :--- | :--- |
| [`foundation/`](foundation/) | Composes private VPC, ECS platform cluster, VPC endpoints, ECR registry, DynamoDB session store, Cognito user pool, and S3 artifact bucket. | **Local Apply & Destroy** (`make apply STACK=foundation`) |
| [`private-application/`](private-application/) | Fargate private microservice blueprint interface ([`aws.modules.blueprint-microservice-private`](https://github.com/hatan4ik/aws.modules.blueprint-microservice-private)). | **Contract Validation Only** (`make contract`) |
| [`edge-web/`](edge-web/) | Edge delivery blueprint interface with CloudFront, S3 origin, WAF, ACM, and Route 53 ([`aws.modules.blueprint-edge-web-app`](https://github.com/hatan4ik/aws.modules.blueprint-edge-web-app)). | **Contract Validation Only** (`make contract`) |
| [`governance-contracts/`](governance-contracts/) | Interface guardrails asserting emulator scope boundaries and tagging rules. | **Contract Validation Only** |

---

## Naming Conventions & Tagging

To maintain strict alignment with production standards while preventing emulator resources from being confused with real sandbox infrastructure:

- Every stack invokes the signed [`aws.modules.naming` v1.0.1](https://github.com/hatan4ik/aws.modules.naming) module.
- All derived names use the canonical prefix `sandbox-floci-*`:
  - `sandbox-floci-network`
  - `sandbox-floci-platform`
  - `sandbox-floci-identity`
  - `sandbox-floci-platform-application`
  - `sandbox-floci-artifacts-000000000000`
- Mandatory local isolation tags are applied automatically:
  ```text
  DeploymentScope = "local"
  Emulator        = "floci"
  Environment     = "sandbox"
  ManagedBy       = "terraform"
  Repository      = "devops-aws-infra"
  ```

---

## Lifecycle: Stop, Reset & Cleanup

| Action | Command | Effect |
| :--- | :--- | :--- |
| **Stop Floci** | `make down` | Stops the emulator containers (`floci` and `floci-aws-ui`). Persists local state and data volumes. |
| **Start Floci** | `make up` | Starts or resumes the emulator in the background. |
| **View Logs** | `make logs` | Streams live container logs from Floci core emulator. |
| **Reset State** | `make reset` | Stops containers and **deletes the `floci-local-data` Docker volume**. Returns the emulator to a pristine zero-resource state. |

---

## Troubleshooting & Diagnostics Playbook

### 1. Port 4566 or 4500 is already in use
- **Symptom:** `docker compose up` fails with `bind: address already in use`.
- **Diagnosis:**
  ```bash
  lsof -nP -iTCP:4566 -sTCP:LISTEN
  lsof -nP -iTCP:4500 -sTCP:LISTEN
  ```
- **Remediation:** Stop the conflicting process or lingering container:
  ```bash
  docker rm -f floci floci-aws-ui 2>/dev/null || true
  ```

### 2. Docker socket permission errors
- **Symptom:** Floci starts, but ECS tasks, Lambda, or clicking "Open UI" fails with permission errors accessing `/var/run/docker.sock`.
- **Diagnosis:** Floci requires Docker socket access to launch sidecar and task containers.
- **Remediation:**
  - On Docker Desktop: Ensure **Settings -> Advanced -> Allow default Docker socket** is enabled.
  - On Linux: Ensure your workstation user is part of the `docker` group (`sudo usermod -aG docker $USER`).

### 3. Web UI Console does not appear or redirects to localhost:4500 connection refused
- **Symptom:** Navigating to `http://localhost:4500` shows connection refused.
- **Diagnosis:** The web UI container is an on-demand dynamic sidecar. It is not started by `docker compose up`.
- **Remediation:**
  1. Open `http://localhost:4566/` in your browser.
  2. Click **"Open UI"** (or hit `curl -s http://localhost:4566/_floci/ui >/dev/null`).
  3. Verify the container started: `docker ps --filter "name=floci-aws-ui"`.
  4. Now open `http://localhost:4500/`.

### 4. Region mismatch (`us-east-1` vs `us-east-2`)
- **Symptom:** `make verify-region` fails or AWS CLI commands default to `us-east-1`.
- **Diagnosis:** Shell environment variables or Docker configuration did not inherit `us-east-2`.
- **Remediation:**
  ```bash
  source ../../tools/floci/env.sh
  make verify-region
  ```
  Ensure `FLOCI_DEFAULT_REGION=us-east-2` appears in `docker inspect floci`.

### 5. Terraform module download errors in local stack
- **Symptom:** `make init STACK=foundation` fails with Git or SSH authentication errors.
- **Diagnosis:** A global Git configuration (such as URL rewrites from HTTPS to SSH) is interfering with module cloning.
- **Remediation:** `bin/tf-local.sh` automatically forces `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM=1`. Always execute Terraform via `make init STACK=...` or `bin/tf-local.sh`, never raw `terraform init`.

### 6. Corrupted local emulator state
- **Symptom:** Resources fail to delete, or strange API behavior occurs in Floci.
- **Remediation (Pristine Reset):**
  ```bash
  cd local/floci
  make reset
  make up
  make verify-region
  make smoke
  ```
