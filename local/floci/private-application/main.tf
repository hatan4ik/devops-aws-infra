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

module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=v1.0.1"

  environment     = "sandbox"
  root            = "floci-private-application"
  repository      = "hatan4ik/devops-aws-infra"
  name_components = ["sandbox", "floci", "orders"]
  additional_names = {
    platform = ["sandbox", "floci", "platform"]
    registry = ["sandbox", "floci", "platform", "application"]
  }
  base_tags = var.naming_base_tags
}

# Contract-only: validates the public interface and immutable dependency graph
# of the composed private-service blueprint. Run it with `make contract`; do
# not apply it until the Floci compatibility matrix explicitly says it works.
module "service" {
  source = "git::https://github.com/hatan4ik/aws.modules.blueprint-microservice-private.git?ref=v2.0.0"

  name        = module.naming.name_prefix
  cluster_arn = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${module.naming.names.platform}-cluster"

  network = {
    cidr_block         = var.vpc_cidr
    availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  }

  container = {
    image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.localhost:4566/${module.naming.names.registry}@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  # Floci cannot prove a public TLS edge. Explicit plain HTTP is a local
  # contract setting only; production must supply an ACM certificate.
  load_balancer = {
    allow_plain_http = true
  }

  tags = module.naming.tags
}
