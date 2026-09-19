variable "config" {
  description = "Configuration for the Cognito User Pool"
  type = object({
    pool_name               = string
    environment             = string
    domain_prefix           = string
    callback_urls           = list(string)
    logout_urls             = list(string)
    advanced_security_mode  = optional(string, "ENFORCED")
    enable_mfa              = optional(string, "ON")
    minimum_password_length = optional(number, 14)
    tags                    = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = contains(["ENFORCED", "AUDIT", "OFF"], var.config.advanced_security_mode)
    error_message = "Advanced security mode must be ENFORCED, AUDIT, or OFF."
  }

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.config.enable_mfa)
    error_message = "MFA mode must be OFF, ON, or OPTIONAL."
  }
}

