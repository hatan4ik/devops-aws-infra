# Runbook: Terraform state restore

## Purpose and authority

Use only to restore a corrupted or accidentally changed Terraform state object.
This is a metadata recovery procedure, not permission to recreate, destroy, or
modify AWS resources. It applies to the transitional legacy backend only after
the [adoption runbook](adopt-legacy-state-backend.md) has established canonical
ownership. Before that point, follow the adoption runbook's rollback procedure.

The incident commander, Platform/DevOps Lead, and a Security approver must
approve the action. Pause all plan/apply jobs, verify that the DynamoDB lock is
not owned by an active operation, and record account, Region, protected state
key, current version ID, target version ID, reason, and rollback owner in the
change record. Never paste the state contents into tickets or logs.

## Restore procedure

1. Re-authenticate with an approved short-lived IAM Identity Center session;
   set identifiers only in the protected change environment. Confirm account
   identity with `aws sts get-caller-identity`.
2. Download the current object and its SHA-256 digest to an encrypted,
   access-controlled incident workspace. Obtain the intended historical S3
   version ID with `aws s3api list-object-versions`; do not delete any version.
3. Run `terraform init -reconfigure` with the approved backend file and
   `terraform state pull > current.tfstate`; compare its digest with the S3
   current-object backup. Stop if they do not match.
4. Download the selected historical version, validate it with
   `terraform show -json` or a reviewed state parser, and obtain Security and
   Platform approval of its lineage. Do not use `terraform state push` until
   both approvers have checked the target version and the rollback copy.
5. Push exactly the approved recovered file with `terraform state push -force
   recovered.tfstate`. Record the resulting S3 version ID and retain both
   current and recovered digests as evidence.
6. Run a refresh-only plan with no configuration changes. Any proposed resource
   create, update, delete, replacement, provider-upgrade surprise, or account/
   Region mismatch is an incident: stop, preserve evidence, and escalate.

## Completion and rollback

Completion requires the no-change refresh-only plan, a confirmed lock-table
state, CloudTrail evidence for the restore, restored backup/version IDs,
approver names, and an incident review. If the restored metadata is wrong,
stop all Terraform operations and restore the immediately previous S3 version
using the same approvals and evidence process. Object Lock retention is not a
substitute for this tested procedure.
