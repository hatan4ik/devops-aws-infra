terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.35.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Local execution still follows the shared platform naming contract. The
# module's environment vocabulary intentionally has no "local" value, so
# sandbox identifies the isolated non-production class while the base tags
# make the Floci boundary explicit.
module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=v1.0.1"

  environment     = "sandbox"
  root            = "floci-foundation"
  repository      = "hatan4ik/devops-aws-infra"
  name_components = ["sandbox", "floci", "platform"]
  additional_names = {
    network   = ["sandbox", "floci", "network"]
    platform  = ["sandbox", "floci", "platform"]
    registry  = ["sandbox", "floci", "platform", "application"]
    identity  = ["sandbox", "floci", "identity"]
    artifacts = ["sandbox", "floci", "artifacts"]
  }
  base_tags = var.naming_base_tags
}

# These are immutable commits behind signed release tags.  The stack is an
# isolated local proving ground, not a replacement for infra/active state.
module "network" {
  source = "git::https://github.com/hatan4ik/aws.modules.vpc.git?ref=v1.1.1"

  name       = module.naming.names.network
  cidr_block = var.vpc_cidr
  tags       = module.naming.tags

  subnets = {
    private = {
      availability_zones = {
        az1 = { availability_zone = "${var.aws_region}a", cidr_block = cidrsubnet(var.vpc_cidr, 4, 0) }
        az2 = { availability_zone = "${var.aws_region}b", cidr_block = cidrsubnet(var.vpc_cidr, 4, 1) }
      }
    }
  }

  # Floci reports incomplete CloudWatch log-group attributes for VPC Flow
  # Logs, which makes every subsequent Terraform plan replace them. Exclude
  # them from the local fixture so its tested subset remains idempotent.
  # The production module default keeps flow logs enabled.
  flow_logs = null

  # Floci 2.2.0 rejects CreateVpcEncryptionControl. The production module
  # default remains enforce; this local-only exception is recorded in the
  # compatibility matrix rather than pretending the control was tested.
  vpc_encryption_control = null
}

module "platform" {
  source = "git::https://github.com/hatan4ik/aws.modules.ecs.git?ref=v1.0.0"

  name                    = module.naming.names.platform
  region                  = var.aws_region
  vpc_id                  = module.network.vpc_id
  vpc_cidr                = var.vpc_cidr
  private_subnet_ids      = toset(values(module.network.subnet_ids_by_tier.private))
  private_route_table_ids = toset(values(module.network.route_table_ids_by_tier.private))

  # This is the same private service reachability model as the active AWS
  # platform root. Floci may report an unsupported endpoint independently.
  interface_endpoint_services = ["cognito-idp", "ecr.api", "ecr.dkr", "logs", "secretsmanager", "ssm", "sts"]
  gateway_endpoint_services   = ["dynamodb", "s3"]
  log_retention_in_days       = 14

  # A disposable local stack must be destroyable. Production keeps the secure
  # module defaults and uses the active root's lifecycle decisions instead.
  # The platform's embedded registry has a production-safe default lifecycle
  # policy. Floci rejects that policy's numeric encoding, so the local fixture
  # creates the same released registry submodule below with no policy instead.
  create_registry = false
  session_store = {
    deletion_protection_enabled    = false
    point_in_time_recovery_enabled = false
  }
  tags = module.naming.tags
}

module "application_registry" {
  source = "git::https://github.com/hatan4ik/aws.modules.ecs.git//modules/registry?ref=v1.0.0"

  name             = module.naming.names.registry
  kms_key_arn      = module.platform.application_data_kms_key_arn
  force_delete     = true
  lifecycle_policy = null
  tags             = module.naming.tags
}

module "identity" {
  source = "git::https://github.com/hatan4ik/aws.modules.cognito.git?ref=v2.0.0"

  name                = module.naming.names.identity
  feature_plan        = "ESSENTIALS"
  deletion_protection = false
  mfa_configuration   = "OPTIONAL"
  password_policy = {
    minimum_length                   = 14
    temporary_password_validity_days = 7
  }
  clients = {
    local_web = {
      callback_urls          = ["https://app.localhost/auth/callback"]
      logout_urls            = ["https://app.localhost/auth/logout"]
      allowed_oauth_scopes   = ["openid", "email"]
      access_token_validity  = 60
      id_token_validity      = 60
      refresh_token_validity = 7
      generate_secret        = false
    }
  }
  tags = module.naming.tags
}

module "application_artifacts" {
  source = "git::https://github.com/hatan4ik/aws.modules.s3.git?ref=v1.0.2"

  bucket        = "${module.naming.names.artifacts}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = module.naming.tags
}
