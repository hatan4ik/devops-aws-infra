variable "name" {
  description = "Lowercase name for this regional network hub."
  type        = string
  nullable    = false
}

variable "amazon_side_asn" {
  description = "Approved private BGP ASN for the regional Transit Gateway."
  type        = number
  nullable    = false
}

variable "route_domains" {
  description = "Network-owned TGW route domains. The default keeps production, non-production, shared, inspection, and on-premises routing separate."
  type        = set(string)
  default     = ["prod", "non-prod", "shared", "inspection", "on-prem"]
  nullable    = false
}

variable "ram_principals" {
  description = "Approved 12-digit AWS account IDs or AWS Organizations organization/OU ARNs for the TGW RAM share. IAM principals are deliberately invalid."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "flow_log_retention_in_days" {
  description = "Retention period for encrypted TGW Flow Logs. The network baseline is at least one year."
  type        = number
  default     = 365
  nullable    = false
}

variable "rejected_traffic_alarm_threshold" {
  description = "Rejected TGW flow-log records in five minutes that trigger the network alarm."
  type        = number
  default     = 1
  nullable    = false
}

variable "rejected_traffic_alarm_actions" {
  description = "Optional SNS or incident-management action ARNs for rejected TGW traffic."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "routing" {
  description = "Network-account-owned attachment catalog and explicit propagation/static-route policy. Null creates the hub only; a workload account never supplies this value."
  type = object({
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
  })
  default  = null
  nullable = true
}

variable "tags" {
  description = "Allocation and ownership tags passed unchanged to the TGW hub module."
  type        = map(string)
  default     = {}
  nullable    = false
}
