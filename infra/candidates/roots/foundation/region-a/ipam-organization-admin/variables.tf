variable "aws_region" {
  description = "Approved primary AWS Region selected through the reviewed regional_region_registry. The IPAM organization-admin prerequisite runs in the same home Region."
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
  description = "AWS Organizations management-account ID permitted to delegate VPC IPAM administration."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "delegated_ipam_admin_account_id" {
  description = "Reviewed Network-account ID delegated to administer VPC IPAM and create shared pools."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.delegated_ipam_admin_account_id))
    error_message = "delegated_ipam_admin_account_id must be a 12-digit AWS account ID."
  }
}

variable "tags" {
  description = "Required allocation and ownership tags."
  type        = map(string)
  default     = {}
  nullable    = false
}
