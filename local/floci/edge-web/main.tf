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
  root            = "floci-edge-web"
  repository      = "hatan4ik/devops-aws-infra"
  name_components = ["sandbox", "floci", "web"]
  additional_names = {
    origin      = ["sandbox", "floci", "web", "assets"]
    access_logs = ["sandbox", "floci", "web", "logs"]
  }
  base_tags = var.naming_base_tags
}

# Contract-only: CloudFront, an ACM certificate in us-east-1, public DNS
# validation, and WAF logging must be tested in AWS. This verifies that our
# caller configuration continues to match the released blueprint interface.
module "web" {
  source = "git::https://github.com/hatan4ik/aws.modules.blueprint-edge-web-app.git?ref=v1.0.1"

  name       = module.naming.name_prefix
  account_id = data.aws_caller_identity.current.account_id
  buckets = {
    origin      = "${module.naming.names.origin}-${data.aws_caller_identity.current.account_id}"
    access_logs = "${module.naming.names.access_logs}-${data.aws_caller_identity.current.account_id}"
  }
  domain = {
    name      = "${module.naming.name_prefix}.${var.zone_name}"
    zone_name = var.zone_name
    zone_id   = var.zone_id
  }
  force_destroy = true
  tags          = module.naming.tags
}
