# Retired sandbox CloudFormation bootstrap

This directory is historical evidence only. It contains the three
CloudFormation stacks and their bootstrap/reconciliation scripts that created
the sandbox GitHub OIDC provider, roles, and delivery policies before Terraform
became the system of record.

Do not run the archived scripts or templates. The controlled handoff has
already completed: Terraform imported every physical resource and attachment,
then the three CloudFormation stack records were deleted with `Retain`
metadata. The historical retirement helper is retained in
[`scripts/retire-sandbox-delivery-cloudformation.sh`](scripts/retire-sandbox-delivery-cloudformation.sh)
for audit only and exits without making AWS calls. These files create no AWS
resources.
