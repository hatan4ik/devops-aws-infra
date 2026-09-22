variable "aws_region" {
  description = "Approved AWS Region for the private sandbox workload root."
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

variable "log_retention_in_days" {
  description = "CloudWatch application-log retention for workload services."
  type        = number
  nullable    = false
}

variable "applications" {
  description = "Private Fargate applications keyed by stable service name. Keep empty until an approved immutable image and runtime contract exist."
  type = map(object({
    image_digest  = string
    cpu           = number
    memory        = number
    desired_count = number
    autoscaling = object({
      min_capacity       = number
      max_capacity       = number
      cpu_target_percent = optional(number, 60)
    })
    container_port              = optional(number)
    command                     = optional(list(string), [])
    environment                 = optional(map(string), {})
    secret_arns                 = optional(map(string), {})
    secret_kms_key_arns         = optional(set(string), [])
    task_policy_statements      = optional(map(object({ actions = set(string), resources = set(string) })), {})
    enable_session_table_access = optional(bool, false)
    ingress_security_group_ids  = optional(set(string), [])
    enable_execute_command      = optional(bool, false)
    readonly_root_filesystem    = optional(bool, true)
    ephemeral_storage_gib       = optional(number)
    cpu_architecture            = optional(string, "X86_64")
    health_check = optional(object({
      command      = list(string)
      interval     = number
      timeout      = number
      retries      = number
      start_period = number
    }))
    cognito = optional(object({
      callback_urls                = set(string)
      logout_urls                  = set(string)
      allowed_oauth_scopes         = set(string)
      supported_identity_providers = optional(set(string), ["COGNITO"])
    }))
    tags = optional(map(string), {})
  }))
  default  = {}
  nullable = false
}
