variable "aws_region" {
  description = "Approved primary AWS Region selected through the reviewed regional_region_registry. AWS requires IPAM RAM shares to be administered from this home Region."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS Region identifier."
  }
}

variable "regional_region_registry" {
  description = "Reviewed primary/secondary Region pair supplied identically to every Regional foundation and network root. Values must be distinct."
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
  description = "Delegated Network-account ID permitted to create the organization-owned IPAM and RAM shares."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "ipam" {
  description = "Reviewed enterprise address-space allocation and account/Organizations sharing contract. No workload root discovers this state directly."
  type = object({
    name              = string
    operating_regions = set(string)
    top_level_cidr    = string
    regional_pools = map(object({
      locale                            = string
      cidr                              = string
      allocation_default_netmask_length = number
      allocation_min_netmask_length     = optional(number)
      allocation_max_netmask_length     = optional(number)
      allocation_resource_tags          = optional(map(string), {})
      ram_principals                    = optional(set(string), [])
    }))
  })
  nullable = false
}

variable "tags" {
  description = "Required allocation and ownership tags."
  type        = map(string)
  default     = {}
  nullable    = false
}
