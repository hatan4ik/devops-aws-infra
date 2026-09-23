locals {
  default_tags = merge(var.tags, {
    Environment = "shared"
    ManagedBy   = "terraform"
    Root        = "foundation-ipam-organization-admin"
  })
}
