variable "config" {
  description = "Configuration for the workload VPC"
  type = object({
    vpc_name             = string
    environment          = string
    ipv4_ipam_pool_id    = string # Required IPAM pool integration
    ipv4_netmask_length  = number # Netmask length to request from IPAM
    azs                  = list(string)
    enable_nat_gateway   = optional(bool, true)
    enable_vpc_endpoints = optional(bool, true)
    tags                 = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.config.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }

  validation {
    condition     = length(var.config.azs) >= 2
    error_message = "VPC must span at least 2 Availability Zones for high availability."
  }

  validation {
    condition     = var.config.ipv4_netmask_length >= 16 && var.config.ipv4_netmask_length <= 24
    error_message = "VPC netmask length must be between /16 and /24."
  }
}
