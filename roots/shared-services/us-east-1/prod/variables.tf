variable "state_bucket_prefix" {
  description = "Prefix for the state bucket"
  type        = string
}

variable "state_lock_table_name" {
  description = "Name for the state lock table"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

