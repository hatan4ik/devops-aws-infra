variable "aws_region" {
  description = "Approved AWS Region for the sandbox platform core."
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
    error_message = "This root is intentionally pinned to the sandbox account."
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
  description = "Name tag of the already deployed sandbox VPC."
  type        = string
  nullable    = false

  validation {
    condition     = var.network_name == "sandbox-network-dev"
    error_message = "This root consumes only the approved sandbox-network-dev VPC."
  }
}

variable "platform_name" {
  description = "Stable resource prefix for the sandbox platform core."
  type        = string
  nullable    = false
}

variable "log_retention_in_days" {
  description = "CloudWatch application log retention."
  type        = number
  nullable    = false
}

variable "tags" {
  description = "Required ownership and cost-allocation tags."
  type = object({
    Application = string
    CostCenter  = string
    Owner       = string
  })
  nullable = false
}
