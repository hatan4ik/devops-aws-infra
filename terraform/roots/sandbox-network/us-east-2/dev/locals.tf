locals {
  default_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "hatan4ik/devops-aws-infra"
    Root        = "sandbox-network"
  })
}
