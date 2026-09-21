variable "aws_region" {
  description = "Approved Region containing the sandbox delivery state backend."
  type        = string
  nullable    = false

  validation {
    condition     = var.aws_region == "us-east-2"
    error_message = "This root is intentionally pinned to us-east-2."
  }
}

variable "aws_account_id" {
  description = "Sandbox account permitted by this IAM delivery root."
  type        = string
  nullable    = false

  validation {
    condition     = var.aws_account_id == "448871779014"
    error_message = "This root is intentionally pinned to the approved sandbox account."
  }
}

variable "role_prefix" {
  description = "Existing GitHub OIDC role-name prefix in the sandbox account."
  type        = string
  nullable    = false

  validation {
    condition     = var.role_prefix == "devops-aws-infra-sandbox"
    error_message = "This root adopts only the approved sandbox GitHub OIDC role prefix."
  }
}

variable "github_subject_prefix" {
  description = "Immutable GitHub OIDC repository subject prefix, excluding its environment/ref suffix."
  type        = string
  nullable    = false
}

variable "github_oidc_thumbprints" {
  description = "Current approved SHA-1 thumbprints for GitHub's OIDC provider."
  type        = set(string)
  nullable    = false
}

variable "state_backend" {
  description = "Dedicated non-secret state configuration for this Terraform root."
  type = object({
    bucket_name     = string
    key_prefix      = string
    kms_key_id      = string
    lock_table_name = string
  })
  nullable = false

  validation {
    condition     = var.state_backend.key_prefix == "gitops/sandbox-delivery/us-east-2/global/"
    error_message = "This root must use its isolated sandbox-delivery state prefix."
  }
}
