variable "aws_region" {
  description = "Approved AWS Region containing the legacy bootstrap state backend."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS Region identifier."
  }
}

variable "aws_account_id" {
  description = "Approved account ID containing the adopted bootstrap state backend."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "legacy_state_backend" {
  description = "Observed non-secret bootstrap settings. Copy the approved inventory exactly before an import or state-address move."
  type = object({
    bucket_name                          = string
    dynamodb_table_name                  = string
    kms_key_alias                        = string
    kms_key_description                  = string
    kms_key_deletion_window_in_days      = number
    object_lock_retention_mode           = string
    object_lock_retention_days           = number
    dynamodb_deletion_protection_enabled = bool
    tags                                 = map(string)
  })
  nullable = false
}
