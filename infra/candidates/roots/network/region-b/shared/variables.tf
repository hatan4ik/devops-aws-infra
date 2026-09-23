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
  description = "Vended Network account ID allowed by this root's provider."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "environment" {
  description = "Fixed root environment label for shared network infrastructure."
  type        = string
  nullable    = false

  validation {
    condition     = var.environment == "shared"
    error_message = "The network hub root environment must be shared."
  }
}

variable "network" {
  description = "Typed regional TGW hub input; ASN and RAM principals must come from approved network governance."
  type = object({
    name                             = string
    amazon_side_asn                  = number
    route_domains                    = optional(set(string), ["prod", "non-prod", "shared", "inspection", "on-prem"])
    ram_principals                   = optional(set(string), [])
    flow_log_retention_in_days       = optional(number, 365)
    rejected_traffic_alarm_threshold = optional(number, 1)
    rejected_traffic_alarm_actions   = optional(set(string), [])
    routing = optional(object({
      approved_account_domains = map(string)
      attachments = map(object({
        attachment_id = string
        account_id    = string
      }))
      propagation_matrix = map(set(string))
      static_routes = optional(map(object({
        route_table_domain     = string
        destination_cidr_block = string
        blackhole              = bool
        target_attachment_key  = optional(string)
      })), {})
    }))
  })
  nullable = false
}

variable "regional_asn_registry" {
  description = "Reviewed Region-to-Amazon-side-ASN registry. Every Regional TGW root receives the same complete map to prevent duplicates."
  type        = map(number)
  nullable    = false

  validation {
    condition = alltrue([
      for asn in values(var.regional_asn_registry) :
      (asn >= 64512 && asn <= 65534) || (asn >= 4200000000 && asn <= 4294967294)
    ])
    error_message = "regional_asn_registry values must be private 16-bit or 32-bit BGP ASNs."
  }
}

variable "tags" {
  description = "Required allocation and ownership tags for all network resources."
  type        = map(string)
  default     = {}
  nullable    = false
}
