variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ipv4_ipam_pool_id" {
  description = "IPAM pool ID"
  type        = string
}

variable "ipv4_netmask_length" {
  description = "Netmask length"
  type        = number
}

variable "azs" {
  description = "List of AZs"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

