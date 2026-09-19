variable "config" {
  description = "Observed, non-secret configuration of the legacy bootstrap state backend. Values must match the approved adoption inventory before state-address migration."
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

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.config.bucket_name))
    error_message = "config.bucket_name must be a valid S3 bucket name."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{3,255}$", var.config.dynamodb_table_name))
    error_message = "config.dynamodb_table_name must be a valid DynamoDB table name."
  }

  validation {
    condition     = can(regex("^alias/[A-Za-z0-9/_-]+$", var.config.kms_key_alias))
    error_message = "config.kms_key_alias must be a KMS alias beginning with alias/."
  }

  validation {
    condition     = var.config.kms_key_deletion_window_in_days >= 7 && var.config.kms_key_deletion_window_in_days <= 30 && floor(var.config.kms_key_deletion_window_in_days) == var.config.kms_key_deletion_window_in_days
    error_message = "config.kms_key_deletion_window_in_days must be a whole number from 7 through 30."
  }

  validation {
    condition     = contains(["COMPLIANCE", "GOVERNANCE"], var.config.object_lock_retention_mode) && var.config.object_lock_retention_days > 0 && floor(var.config.object_lock_retention_days) == var.config.object_lock_retention_days
    error_message = "config object-lock retention requires COMPLIANCE or GOVERNANCE mode and a positive whole-number day count."
  }
}
