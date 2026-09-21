# Retired sandbox CloudFormation bootstrap

This directory is historical evidence only. It contains the three
CloudFormation stacks and their bootstrap/reconciliation scripts that created
the sandbox GitHub OIDC provider, roles, and delivery policies before Terraform
became the system of record.

Do not run the archived scripts. The only permitted use of the retained
templates is the controlled handoff in
[`scripts/retire-sandbox-delivery-cloudformation.sh`](../../scripts/retire-sandbox-delivery-cloudformation.sh):
it updates the retired stacks with `Retain` metadata and deletes them only
after Terraform has imported every physical resource and attachment. Once that
handoff succeeds, the templates remain as audit evidence and create no AWS
resource.
