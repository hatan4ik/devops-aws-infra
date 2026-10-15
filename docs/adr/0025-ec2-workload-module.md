# ADR 0025: EC2 fleet module with Session Manager as the default access path

**Status:** Proposed
**Decision date:** 2026-10-15

## Context

[ADR 0007](0007-compute-and-data.md) chose ECS Fargate for long-running APIs
and Lambda for asynchronous or spiky work. It rejected a universal EKS
runtime, partly because Fargate avoids node operations and node SSH. EC2
instances were not part of that decision, and no module in the catalog can
launch them.

The platform owner has stated that an EC2 module is required. The specific
workload that cannot run on Fargate or Lambda is **not recorded in this
ADR**; the owner should name it before this record is accepted, because it
decides the instance family, the storage shape, and whether a fleet or a
single stateful instance is needed.

This decision is about the module, not about moving any workload to EC2. No
active root consumes it.

## Options considered

1. **A standalone `aws_instance` module.** Simple for one machine, but a
   failed instance is not replaced, a change is a manual replacement, and a
   fleet needs a second module.
2. **An Auto Scaling group with a launch template.** One resource model for a
   fleet and for a single instance (minimum and maximum of one), with
   self-healing and rolling replacement on a template change.
3. **A self-managed ECS or EKS capacity provider on EC2.** Out of scope: it
   reopens the container-runtime decision in ADR 0007.

## Decision

1. Build `aws.modules.ec2` as an Auto Scaling group plus launch template
   (option 2). A single instance is a group of one; there is no separate
   single-instance mode.
2. The module enforces, and exposes no input to weaken: IMDSv2 required,
   encryption on every volume it declares, no public IPv4 address, and
   private subnets supplied by the caller.
3. **Access is a choice.** `access = "ssm"` is the default and the platform
   standard: Session Manager through the instance role, no key pair, no
   inbound rule. `access = "key_pair"` and `"both"` are explicit opt-ins for
   workloads that need SSH. The module registers a caller-supplied **public**
   key or references an existing key pair; it never generates key material,
   so no private key reaches Terraform state. The module does not open port
   22: the security group is the caller's.
4. The module consumes identifiers (subnets, security groups, a KMS key ARN,
   target groups) and creates no network, key, or load balancer. Volumes are
   encrypted with a customer managed key from `aws.modules.kms`, whose
   `autoscaling-ebs` service-grant preset renders the Auto Scaling
   service-linked-role statements.
5. The module is released like every other module: a signed annotated tag,
   the pinned `terraform-pipelines` release workflow, and a catalog row in
   `MODULE-REPOSITORIES.md` after the first signed release.

## Consequences

- **Node operations return.** Patching is an AMI change that rolls the fleet
  through the launch template. The module does not patch, scan, or pick an
  AMI. AMI provenance and who may write a private SSM parameter become part
  of the trust boundary; an SCP or the EC2 allowed-AMIs setting should
  restrict image sources before production use.
- **SSH is available again, by choice.** This departs from the reasoning of
  ADR 0007 ("no node SSH") only for callers that opt in. Using
  `access = "key_pair"` or `"both"` in an active root needs its own review of
  the port 22 rule, the key custody, and Session Manager logging.
- **The module has never been applied to AWS.** Its tests use a mocked
  provider, and the integration suite has not run. Acceptance of this ADR
  should wait for one run of that suite in the sandbox account.
- **A new repository changes the release audit.** `verify-module-release-fleet.sh`
  discovers every public `aws.modules.*` repository and fails until it has a
  signed tag and a matching release. `aws.modules.ec2` will fail it until its
  first release.
- **`aws.modules.kms` needs a release that contains the preset** (merged to
  `main`, not yet tagged) before an example can pin it by signed tag.

## Acceptance conditions

- The workload that needs EC2 is named here, with why Fargate and Lambda do
  not fit.
- The integration suite has run once against the sandbox account and passed,
  including the key pair and SSM paths.
- `aws.modules.kms` has a signed release containing `autoscaling-ebs`.
- `aws.modules.ec2` has a signed `v1.0.0` release and a catalog row.
