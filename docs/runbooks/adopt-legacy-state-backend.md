# Adopt the legacy Terraform state backend

This runbook implements [ADR 0015](../adr/0015-adopt-legacy-state-bootstrap.md).
It changes Terraform state addresses only; it does **not** create, update, or
destroy AWS resources. Do not combine it with the later state-hardening migration.

## Preconditions and stop conditions

1. Use a short-lived IAM Identity Center session in the approved account. Do not use long-lived access keys or commit/document a named local profile.
2. Obtain an approved state-change record with the Platform Owner and required Cloud Architect, Security, SRE, and Platform/DevOps approvals recorded.
3. Run the read-only preflight below. Stop on any caller-account mismatch, missing retention, or missing DynamoDB PITR/SSE.
4. Obtain the **existing** backend key from the protected change record or current operator configuration. Do not enumerate, print, or commit state object keys. Store backend configuration outside the repository.
5. Schedule a maintenance window: Terraform operations that use this state must be paused. The lock table must have no active lock at the start and immediately before the state move.

The legacy source files and local state artefacts are evidence only. The disabled prototype must not be initialized, planned, applied, or used to operate the backend.

## Read-only preflight

Set the following values from the protected adoption inventory or the ignored
`terraform.tfvars`; do not copy the values into this runbook, an issue, or a
shell history file. The profile/session is selected by the operator's normal
credential process and is not named in source.

```bash
scripts/verify-legacy-state-backend-adoption.sh \
  --account-id "$APPROVED_ACCOUNT_ID" \
  --region "$APPROVED_AWS_REGION" \
  --bucket-name "$APPROVED_BUCKET_NAME" \
  --dynamodb-table-name "$APPROVED_LOCK_TABLE_NAME" \
  --kms-key-alias "$APPROVED_KMS_ALIAS" \
  --object-lock-retention-mode "$APPROVED_OBJECT_LOCK_MODE" \
  --object-lock-retention-days "$APPROVED_OBJECT_LOCK_DAYS"
```

The command checks the caller account plus the controls represented by the
canonical adoption source. It makes no AWS write calls and prints no state
object key, state content, or credentials.

## Prepare an isolated operator worktree and backup

1. Start from the reviewed Git commit containing ADR 0015; use a clean,
   access-controlled worktree outside any shared directory.
2. Copy `infra/candidates/roots/foundation/region-a/bootstrap-state/terraform.tfvars.example`
   to an ignored `terraform.tfvars` file and replace **every** placeholder
   from the approved inventory after confirming the STS identity.
3. Create an uncommitted backend file in an access-controlled location. It
   contains the approved bucket, Region, lock table, and existing state key;
   it contains no AWS credentials. Never commit or paste it into an issue.
4. Take an immutable state backup. Record its S3 version ID, SHA-256 digest,
   UTC timestamp, operator, and change record outside the repository.

```bash
root=infra/candidates/roots/foundation/region-a/bootstrap-state

terraform -chdir="$root" init \
  -reconfigure \
  -lockfile=readonly \
  -backend-config=/secure/path/bootstrap-state.backend.hcl
terraform -chdir="$root" state pull \
  > /secure/path/bootstrap-state.before-adoption.tfstate
shasum -a 256 /secure/path/bootstrap-state.before-adoption.tfstate
terraform -chdir="$root" state list
```

The state list must contain exactly these nine historical bindings; stop if an
address is missing or another address appears:

```text
module.tf_state_backend.aws_kms_key.state
module.tf_state_backend.aws_kms_alias.state
module.tf_state_backend.aws_s3_bucket.state
module.tf_state_backend.aws_s3_bucket_public_access_block.state
module.tf_state_backend.aws_s3_bucket_versioning.state
module.tf_state_backend.aws_s3_bucket_server_side_encryption_configuration.state
module.tf_state_backend.aws_s3_bucket_object_lock_configuration.state
module.tf_state_backend.aws_dynamodb_table.lock
module.tf_state_backend.random_id.bucket_suffix
```

## Review and apply the declarative state migration

The canonical root contains eight `moved` blocks, one `import` block for the
live-but-untracked ownership control, and one `removed` block for the obsolete
`random_id`. They are idempotent after a successful apply. Do **not** run
`terraform state mv`, `terraform import`, or `terraform state rm` manually.

```bash
terraform -chdir="$root" plan \
  -lock-timeout=5m \
  -out=/secure/path/adoption-state-only.tfplan
terraform -chdir="$root" show -no-color /secure/path/adoption-state-only.tfplan
```

Before approval, reviewers must see exactly eight address moves, one ownership
control import, and removal of the obsolete helper. The plan must contain no
create, update, replace, or destroy action for an AWS resource. A provider
refresh may reconcile historical state metadata (including the bucket-level
Object Lock flag written by the older provider); it must not propose a remote
resource change. Any other diff is an incident and a stop condition.

Apply only the reviewed plan after the backup digest and zero-lock evidence
are attached to the change record:

```bash
terraform -chdir="$root" apply /secure/path/adoption-state-only.tfplan
```

## Verification, rollback, and completion

```bash
terraform -chdir="$root" state list
terraform -chdir="$root" plan -refresh-only -out=/secure/path/adoption-refresh.tfplan
terraform -chdir="$root" show -no-color /secure/path/adoption-refresh.tfplan
terraform -chdir="$root" plan -out=/secure/path/adoption-nochange.tfplan
terraform -chdir="$root" show -no-color /secure/path/adoption-nochange.tfplan
```

The final state list must contain the nine canonical addresses (eight moved
bindings plus `aws_s3_bucket_ownership_controls.state`) and no
`module.tf_state_backend` address. Both reviewed plans must contain no AWS
resource actions.

If the migration plan, apply, or either verification plan proposes an AWS
resource action, stop. Under a new incident/change record, restore only the
verified backup state metadata, then prove its digest and S3 object version:

```bash
terraform -chdir="$root" state push -force \
  /secure/path/bootstrap-state.before-adoption.tfstate
terraform -chdir="$root" state pull \
  > /secure/path/bootstrap-state.after-rollback.tfstate
shasum -a 256 /secure/path/bootstrap-state.after-rollback.tfstate
aws s3api head-object \
  --bucket "$APPROVED_BUCKET_NAME" \
  --key "$APPROVED_STATE_KEY" \
  --query VersionId \
  --output text
```

The backup and restored digests must match; record the returned S3 version ID
outside the repository. Never roll back by deleting Object-Locked versions.

Record the final state version ID and digest, preflight output, state-address
mapping, lock check, plan evidence, reviewers, and cost owner. Only then may
the prototype's ignored local state artefacts be quarantined. The final
hardening migration (logging, restricted access policies, deletion protection,
and regional recovery) is a separate change and requires its own ADR amendment
and plan.
