variable "aws_region" {
  description = "Approved secondary AWS Region selected through the reviewed regional_region_registry."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS Region identifier."
  }
}

variable "regional_region_registry" {
  description = "Reviewed primary/secondary Region pair supplied identically to both Regional roots. The values must be distinct."
  type        = map(string)
  nullable    = false

  validation {
    condition = (
      can(var.regional_region_registry["primary"]) &&
      can(var.regional_region_registry["secondary"]) &&
      alltrue([for region in values(var.regional_region_registry) : can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", region))])
    )
    error_message = "regional_region_registry must include valid primary and secondary AWS Region values."
  }
}

variable "aws_account_id" {
  description = "Vended production workload account ID allowed by this root's provider."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "environment" {
  description = "Fixed environment label for this root."
  type        = string
  nullable    = false

  validation {
    condition     = var.environment == "prod"
    error_message = "This root is only for prod."
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
      transit_gateway_attachment_subnets = optional(map(object({
        subnet_newbits = number
        subnet_netnum  = number
      })), {})
      transit_gateway_routes = optional(map(object({
        destination_cidr_block = string
        transit_gateway_id     = string
      })), {})
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
    transit_gateway_attachment = optional(object({
      transit_gateway_id     = string
      attachment_key         = string
      appliance_mode_support = optional(bool, false)
    }))
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
