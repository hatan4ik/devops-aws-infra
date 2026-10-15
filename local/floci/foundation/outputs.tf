output "network" {
  value = {
    vpc_id             = module.network.vpc_id
    private_subnet_ids = module.network.subnet_ids_by_tier.private
    route_table_ids    = module.network.route_table_ids_by_tier.private
  }
}

output "platform" {
  value = {
    cluster_arn              = module.platform.cluster_arn
    application_data_kms_arn = module.platform.application_data_kms_key_arn
    registry = {
      repository_arn  = module.application_registry.repository_arn
      repository_name = module.application_registry.repository_name
      repository_url  = module.application_registry.repository_url
    }
    session_store = module.platform.session_store
  }
}

output "identity" {
  value = module.identity.user_pool
}

output "application_artifact_bucket" {
  value = module.application_artifacts.id
}

output "naming" {
  description = "Canonical names and tags used by this local foundation."
  value = {
    prefix = module.naming.name_prefix
    names  = module.naming.names
    tags   = module.naming.tags
  }
}
