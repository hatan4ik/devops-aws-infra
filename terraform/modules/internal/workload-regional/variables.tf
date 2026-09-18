variable "workload_name" {
  description = "Lowercase workload and environment name passed to regional component modules."
  type        = string
  nullable    = false
}

variable "vpc" {
  description = "Typed private VPC, endpoint, and Flow Log configuration."
  type = object({
    ipv4_ipam_pool_id   = string
    ipv4_netmask_length = number
    availability_zones = map(object({
      availability_zone = string
      subnet_newbits    = number
      subnet_netnum     = number
    }))
    interface_endpoints = map(object({
      service_name        = string
      private_dns_enabled = bool
      policy_json         = optional(string)
    }))
    gateway_endpoints = map(object({
      service_name = string
      policy_json  = optional(string)
    }))
    flow_log_kms_key_arn       = string
    flow_log_retention_in_days = number
  })
  nullable = false
}

variable "identity" {
  description = "Primary creates the secure Cognito pool; secondary deliberately creates no independent pool while MRR is provider-blocked."
  type = object({
    mode = string
    user_pool = optional(object({
      name                = string
      feature_plan        = string
      deletion_protection = bool
      mfa_configuration   = string
      password_policy = object({
        minimum_length                   = number
        temporary_password_validity_days = number
      })
      clients = map(object({
        callback_urls          = set(string)
        logout_urls            = set(string)
        allowed_oauth_scopes   = set(string)
        access_token_validity  = number
        id_token_validity      = number
        refresh_token_validity = number
        generate_secret        = bool
      }))
      resource_servers = map(object({
        identifier = string
        name       = string
        scopes = map(object({
          description = string
        }))
      }))
    }))
  })
  nullable = false

  validation {
    condition     = contains(["primary", "secondary"], var.identity.mode)
    error_message = "identity.mode must be primary or secondary."
  }

  validation {
    condition = (
      (var.identity.mode == "primary" && var.identity.user_pool != null) ||
      (var.identity.mode == "secondary" && var.identity.user_pool == null)
    )
    error_message = "primary identity needs a user_pool configuration; secondary identity must not create an independent pool."
  }
}

variable "tags" {
  description = "Allocation and ownership tags passed to the regional component modules."
  type        = map(string)
  default     = {}
  nullable    = false
}
