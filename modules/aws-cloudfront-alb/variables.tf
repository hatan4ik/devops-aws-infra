variable "config" {
  description = "Configuration for CloudFront and ALB"
  type = object({
    name                 = string
    environment          = string
    primary_alb_domain   = string
    secondary_alb_domain = optional(string, "")
    enable_waf           = optional(bool, true)
    tags                 = optional(map(string), {})
  })
  nullable = false
}
