locals {
  # Root-owned tags make every regional TGW resource traceable to its account/environment boundary.
  default_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Root        = "network"
  })
}
