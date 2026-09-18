variable "config" {
  description = "Configuration object for the Terraform state backend."
  type = object({
    bucket_prefix = string
    table_name    = string
    kms_key_alias = optional(string, "alias/terraform-state-backend")
    environment   = string
    tags          = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = length(var.config.bucket_prefix) > 0 && length(var.config.bucket_prefix) <= 37
    error_message = "Bucket prefix must be between 1 and 37 characters to allow room for the random suffix."
  }

  validation {
    condition     = contains(["dev", "staging", "prod", "shared"], var.config.environment)
    error_message = "Environment must be one of: dev, staging, prod, shared."
  }
}
