variable "config" {
  description = "Configuration for the ECS Fargate Cluster"
  type = object({
    cluster_name              = string
    environment               = string
    enable_container_insights = optional(bool, true)
    tags                      = optional(map(string), {})
  })
  nullable = false
}

