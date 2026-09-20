variable "aws_region" {
  description = "Approved AWS Region for this sandbox network root."
  type        = string
  nullable    = false

  validation {
    condition     = var.aws_region == "us-east-2"
    error_message = "This root is intentionally pinned to us-east-2."
  }
}

variable "aws_account_id" {
  description = "Sandbox AWS account ID permitted by this root's provider."
  type        = string
  nullable    = false

  validation {
    condition     = var.aws_account_id == "448871779014"
    error_message = "This root is intentionally pinned to the approved sandbox account."
  }
}

variable "environment" {
  description = "Fixed environment label for this root."
  type        = string
  nullable    = false

  validation {
    condition     = var.environment == "dev"
    error_message = "This root is only for dev."
  }
}

variable "network_name" {
  description = "Stable resource prefix for the sandbox VPC."
  type        = string
  nullable    = false
}

variable "vpc_cidr" {
  description = "Approved sandbox VPC CIDR."
  type        = string
  nullable    = false

  validation {
    condition     = var.vpc_cidr == "10.64.0.0/16"
    error_message = "This root is approved only for 10.64.0.0/16."
  }
}

variable "availability_zones" {
  description = "Sandbox-account Availability Zones selected during read-only preflight."
  type        = map(string)
  nullable    = false
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs selected from the approved VPC CIDR."
  type        = map(string)
  nullable    = false
}

variable "flow_log_retention_in_days" {
  description = "CloudWatch Logs retention for bootstrap VPC Flow Logs, at least one year."
  type        = number
  default     = 365
  nullable    = false
}

variable "tags" {
  description = "Required ownership and cost-allocation tags."
  type        = map(string)
  nullable    = false
}
