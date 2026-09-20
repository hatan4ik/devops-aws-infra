# Adopt the legacy Terraform state backend

This runbook implements [ADR 0015](../adr/0015-adopt-legacy-state-bootstrap.md).
It changes Terraform state addresses only; it does **not** create, update, or
destroy AWS resources. Do not combine it with the later state-hardening migration.

## Preconditions and stop conditions

1. Use a short-lived IAM Identity Center session in the approved account. Do not use long-lived access keys or commit a profile name.
2. Obtain an approved state-change record with the Platform Owner and required Cloud Architect, Security, SRE, and Platform/DevOps approvals recorded.
3. Run the read-only preflight below. Stop on any caller-account mismatch, missing retention, or missing DynamoDB PITR/SSE.
4. Obtain the **existing** backend key from the protected change record or current operator configuration. Do not enumerate, print, or commit state object keys. Store backend configuration outside the repository.
5. Schedule a maintenance window: Terraform operations that use this state must be paused. The lock table must have no active lock at the start and immediately before the state move.

The legacy source files and local state artefacts are evidence only. The disabled prototype must not be initialized, planned, applied, or used to operate the backend.

## Read-only preflight

Set a short-lived profile in your shell, then run:

```bash
AWS_PROFILE=platform-bootstrap \
scripts/verify-legacy-state-backend-adoption.sh \
  --account-id "$APPROVED_ACCOUNT_ID" \
  --region us-east-2
```

The command checks the caller account plus the controls represented by the canonical adoption source. It makes no AWS write calls and prints no state object key, state content, or credentials.

## Prepare an isolated operator worktree

1. Start from the reviewed Git commit containing ADR 0015; use a clean, access-controlled worktree outside any shared directory.
2. Copy `terraform/roots/foundation/region-a/bootstrap-state/terraform.tfvars.example` to an ignored `terraform.tfvars` file. Replace only `REPLACE_WITH_APPROVED_ACCOUNT_ID` after confirming the STS identity.
3. Create an uncommitted backend file in an access-controlled location. It contains the approved bucket, Region, lock table, and existing state key; it contains no AWS credentials. Never commit or paste it into an issue.
4. Take an immutable state backup with the existing backend configuration and record the S3 version ID, SHA-256 digest, UTC timestamp, operator, and change record outside the repository.

```bash
terraform -chdir=terraform/roots/foundation/region-a/bootstrap-state init \
  -reconfigure \
  -backend-config=/secure/path/bootstrap-state.backend.hcl
terraform -chdir=terraform/roots/foundation/region-a/bootstrap-state state pull \
  > /secure/path/bootstrap-state.before-move.tfstate
shasum -a 256 /secure/path/bootstrap-state.before-move.tfstate
terraform -chdir=terraform/roots/foundation/region-a/bootstrap-state state list
```

The list must contain exactly the nine historical addresses documented below. Stop if another address appears or an expected address is missing.

## Move state addresses (approved mutation)

Run these commands only after the backup and review evidence are attached to the change record. They modify Terraform state metadata, not AWS resources.

```bash
root=terraform/roots/foundation/region-a/bootstrap-state

terraform -chdir="$root" state mv \
  'module.tf_state_backend.aws_kms_key.state' \
  'module.legacy_state_backend.aws_kms_key.state'
terraform -chdir="$root" state mv \
  'module.tf_state_backend.aws_kms_alias.state' \
  'module.legacy_state_backend.aws_kms_alias.state'
terraform -chdir="$root" state mv \
  'module.tf_state_backend.aws_s3_bucket.state' \
  'module.legacy_state_backend.aws_s3_bucket.state'
terraform -chdir="$root" state mv \
  'module.tf_state_backend.aws_s3_bucket_public_access_block.state' \
  'module.legacy_state_backend.aws_s3_bucket_public_access_block.state'
terraform -chdir="$root" state mv \
  'module.tf_state_backend.aws_s3_bucket_versioning.state' \
  'module.legacy_state_backend.aws_s3_bucket_versioning.state'
terraform -chdir="$root" state mv \
  'module.tf_state_backend.aws_s3_bucket_server_side_encryption_configuration.state' \
  'module.legacy_state_backend.aws_s3_bucket_server_side_encryption_configuration.state'
terraform -chdir="$root" state mv \
  'module.tf_state_backend.aws_s3_bucket_object_lock_configuration.state' \
  'module.legacy_state_backend.aws_s3_bucket_object_lock_configuration.state'
terraform -chdir="$root" state mv \
  'module.tf_state_backend.aws_dynamodb_table.lock' \
  'module.legacy_state_backend.aws_dynamodb_table.state_lock'

# The historical state did not track ownership controls, although the live
# bucket is BucketOwnerEnforced. Importing this existing control changes state
# metadata only and avoids an otherwise redundant AWS write in the no-change
# plan.
terraform -chdir="$root" import \
  'module.legacy_state_backend.aws_s3_bucket_ownership_controls.state' \
  'platform-tf-state-shared-f3ddb8cc'
```

After the moves, compare the state list to the new addresses. The remaining `module.tf_state_backend.random_id.bucket_suffix` is metadata for a name that is now fixed. Remove it **only** after the above moves succeed and the backup digest has been independently verified:

```bash
terraform -chdir="$root" state rm \
  'module.tf_state_backend.random_id.bucket_suffix'
```

## Verification and completion

```bash
terraform -chdir="$root" plan -refresh-only -out=/secure/path/adoption-refresh.tfplan
terraform -chdir="$root" show -no-color /secure/path/adoption-refresh.tfplan
terraform -chdir="$root" plan -out=/secure/path/adoption-nochange.tfplan
terraform -chdir="$root" show -no-color /secure/path/adoption-nochange.tfplan
```

Both reviewed plans must contain **no AWS resource actions**. If either plan does, stop and restore the state metadata only from the verified backup under a new incident/change record; do not apply either plan.

Record the final state version ID and digest, preflight output, state-address mapping, lock check, plan evidence, reviewers, and cost owner. Only then may the prototype’s ignored local state artefacts be quarantined. The final hardening migration (logging, restricted access policies, deletion protection, and regional recovery) is a separate change and requires its own ADR amendment and plan.
