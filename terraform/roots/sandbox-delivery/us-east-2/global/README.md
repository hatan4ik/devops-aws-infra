# Sandbox delivery IAM root

This root is the sole owner of the sandbox GitHub Actions OIDC provider, all
six GitHub roles, four network/platform delivery policies, and their role
attachments. It adopts every one of those resources from the historical
CloudFormation stacks using declarative import blocks, then adds the limited
policy-management permission needed for protected GitHub OIDC delivery of
later policy revisions.

This root does not create application, VPC, account, or credential resources.
Its first apply is the documented short-lived IAM Identity Center adoption
exception; after adoption, protected GitHub Actions is the only Terraform
apply path and the sandbox contains no active CloudFormation stack.

The backend uses the stable `alias/terraform-state-backend` KMS alias. It
avoids repeating an account-qualified KMS ARN while requiring customer-managed
SSE-KMS for the state and lock files.
