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

variable "ram_principal_arns" {
  description = "Approved AWS Organizations or account principals for the TGW RAM share."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "tags" {
  description = "Allocation and ownership tags passed unchanged to the TGW hub module."
  type        = map(string)
  default     = {}
  nullable    = false
}
