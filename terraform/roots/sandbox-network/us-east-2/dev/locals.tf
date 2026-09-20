locals {
  # Convert typed tag object to map(string) before merging with computed root tags.
  default_tags = merge(tomap(var.tags), {
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "hatan4ik/devops-aws-infra"
    Root        = "sandbox-network"
  })
}
