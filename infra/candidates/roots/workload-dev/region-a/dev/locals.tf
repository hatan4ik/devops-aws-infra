locals {
  # Root-owned tags bind this code to one account, Region, and environment tuple.
  default_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Root        = "workload"
  })
}
