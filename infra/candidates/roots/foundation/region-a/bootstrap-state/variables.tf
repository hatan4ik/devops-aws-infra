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

variable "bucket_name" {
  description = "Approved observed bucket name, supplied only from the protected adoption inventory."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid S3 bucket name."
  }
}

variable "dynamodb_table_name" {
  description = "Approved observed DynamoDB lock-table name, supplied only from the protected adoption inventory."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{3,255}$", var.dynamodb_table_name))
    error_message = "dynamodb_table_name must be a valid DynamoDB table name."
  }
}

variable "kms_key_alias" {
  description = "Approved observed KMS alias, supplied only from the protected adoption inventory."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^alias/[A-Za-z0-9/_-]+$", var.kms_key_alias))
    error_message = "kms_key_alias must be a KMS alias beginning with alias/."
  }
}

variable "kms_key_description" {
  description = "Approved observed, non-secret KMS key description."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.kms_key_description)) > 0
    error_message = "kms_key_description must not be empty."
  }
}

variable "tags" {
  description = "Approved observed ownership and allocation tags."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain the approved ownership and allocation tags."
  }
}
