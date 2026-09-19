# Delivery walkthrough and state boundary

## Current status

No AWS state backend has been initialized, no plan has been approved, and no
Terraform apply is authorized from this repository. The source contains no
cloud credentials, state, or evidence of a completed state migration.

The previous walkthrough in this location described an `us-east-2` prototype,
an authenticated local profile, and a completed state migration. That material
belonged to the root-level prototype tree, conflicted with the authoritative
architecture, and is superseded by [ADR 0014](adr/0014-canonical-architecture-and-iac-boundary.md).
The prototype roots no longer contain a backend or named profile and fail a
normal Terraform plan.

## Approved delivery sequence

1. Complete the [external verification checklist](architecture/external-verification.md), including selected Regions, account structure, CIDRs/ASNs, state retention, KMS ownership, quotas, DNS, and cost approval.
2. Establish human access with IAM Identity Center and CI access with an
   environment-scoped GitHub OIDC role; see the [AWS access bootstrap runbook](runbooks/bootstrap-aws-access.md).
3. Use the candidate source under [`terraform/`](../terraform/README.md), not
   the disabled root-level prototypes. Configure a backend only through an
   approved environment-specific delivery repository and its protected
   workflow.
4. Review a credentialed plan with the authoritative backend and real,
   approved inputs. Preserve a state backup and obtain the required change
   approval before any apply.
5. Capture post-deployment evidence and exercise the read-only, synthetic, and
   operational verification contracts in [`tests/`](../tests/README.md).

The no-implicit-apply and provider-boundary controls are defined by
[ADRs 0011–0013](adr/README.md).
