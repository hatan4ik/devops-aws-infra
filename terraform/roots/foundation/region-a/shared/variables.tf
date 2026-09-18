variable "aws_region" {
  description = "Approved AWS Region for the Shared Services state-backend account. region-a is a directory placeholder, not a Region selection."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS Region identifier."
  }
}

variable "aws_account_id" {
  description = "Vended Shared Services AWS account ID allowed by this root's provider."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "environment" {
  description = "Fixed root environment label. This root uses shared because it owns shared-services state infrastructure."
  type        = string
  nullable    = false

  validation {
    condition     = var.environment == "shared"
    error_message = "The foundation root environment must be shared."
  }
}

variable "state_backend" {
  description = "Typed non-secret state-backend configuration; role ARNs come from the approved OIDC and break-glass design."
  type = object({
    name_prefix = string
    state_tiers = map(object({
      bucket_name                                  = string
      noncurrent_version_expiration_in_days        = number
      abort_incomplete_multipart_upload_after_days = number
      object_lock = object({
        enabled        = bool
        retention_mode = optional(string)
        retention_days = optional(number)
      })
    }))
    state_access_principal_arns     = set(string)
    kms_key_deletion_window_in_days = number
    key_administrator_arns          = set(string)
  })
  nullable = false
}

variable "tags" {
  description = "Required allocation and ownership tags for all foundation resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
