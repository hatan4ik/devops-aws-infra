locals {
  # Root-owned tags keep account/environment provenance uniform without concealing caller-supplied allocation tags.
  default_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Root        = "foundation"
  })
}
