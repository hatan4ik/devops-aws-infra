# Local AWS emulator: Floci

This directory provides a reproducible local AWS development environment for
fast feedback. It is **not** a substitute for the sandbox AWS integration
environment or a place to test multi-account, Control Tower, Transit Gateway,
VPN/BGP, quota, or AWS service-policy behavior.

The Compose definition is pinned to the image digest validated on 2026-10-13.
It mounts the Docker socket because ECS and Lambda-style runtime tests need to
start local containers. Docker socket access is host-privileged: run this only
on a trusted developer workstation, never in CI or AWS.

## Start

```sh
docker compose -f tools/floci/compose.yaml up -d
source tools/floci/env.sh
aws sts get-caller-identity
```

The identity must be the emulator's local account, `000000000000`; it must not
be one of your AWS accounts.
- Floci core emulator endpoint: `http://localhost:4566`
- Floci AWS web UI console: `http://localhost:4500` (launches on demand as a sidecar container when clicking "Open UI" at `http://localhost:4566`)

Both the core emulator and the on-demand web UI are configured and pinned to `us-east-2` (`FLOCI_DEFAULT_REGION=us-east-2` and `FLOCI_DEFAULT_AVAILABILITY_ZONE=us-east-2a` for core; `AWS_REGION=us-east-2` and `AWS_DEFAULT_REGION=us-east-2` for both core and spawned UI).

## Verify the local environment

```sh
source tools/floci/env.sh
tools/floci/smoke.sh
```

The smoke test creates and deletes an SQS queue and ECS cluster in Floci. It
refuses to run unless `AWS_ENDPOINT_URL` is a localhost Floci endpoint.

Check that the emulator and its optional web console use the intended region:

```sh
FLOCI_EXPECTED_REGION=us-east-2 tools/floci/verify-region.sh
```

This is read-only. It verifies `FLOCI_DEFAULT_REGION` on the core emulator and
`AWS_REGION`/`AWS_DEFAULT_REGION` plus `FLOCI_ENDPOINT` on the web UI. It does
not change containers or local state.

## Terraform workflow

The AWS provider receives the local endpoint through `AWS_ENDPOINT_URL`; do
not add a provider block to reusable modules just for local development.

```sh
source tools/floci/env.sh
terraform -chdir=path/to/local-fixture init -backend=false -input=false
terraform -chdir=path/to/local-fixture validate
terraform -chdir=path/to/local-fixture apply -auto-approve
terraform -chdir=path/to/local-fixture destroy -auto-approve
```

Use a dedicated local fixture with no remote backend. Do **not** locally apply
any `infra/active/roots` directory: those roots are GitOps delivery roots with
real remote-state and account dependencies. Keep live AWS verification in the
sandbox account as the final gate.

This repository's maintained fixture catalog is
[`local/floci`](../../local/floci/README.md). Its loopback-only wrapper,
immutable module pins, compatibility matrix, and `terraform.tfvars.example`
files are the supported path for testing the platform and blueprint interfaces
locally.

## Stop and reset

```sh
docker compose -f tools/floci/compose.yaml down
docker compose -f tools/floci/compose.yaml down --volumes # deletes local emulator state
```

## Current validation

- AWS CLI STS returned local account `000000000000`.
- Terraform AWS provider v6 created and destroyed S3 and SQS resources using
  the local endpoint.
- ECS create/delete completed after Docker socket access was enabled.
