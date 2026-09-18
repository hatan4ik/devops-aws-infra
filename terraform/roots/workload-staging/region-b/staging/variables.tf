variable "aws_region" {
  description = "Approved AWS Region for this root. region-b is only a directory placeholder."
  type        = string
  nullable    = false
}

variable "aws_account_id" {
  description = "Vended staging workload account ID allowed by this root's provider."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Fixed environment label for this root."
  type        = string
  nullable    = false

  validation {
    condition     = var.environment == "staging"
    error_message = "This root is only for staging."
  }
}

variable "workload" {
  description = "Typed workload VPC and primary-or-secondary identity configuration. Values must come from the approved account-vending, CIDR, and identity records."
  type = object({
    name = string
    vpc = object({
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
    identity = object({
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
  })
  nullable = false
}

variable "tags" {
  description = "Required allocation and ownership tags."
  type        = map(string)
  default     = {}
  nullable    = false
}
