terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }

  # NOTE: To migrate this root itself to the state backend it manages, 
  # apply this root first with local state, then uncomment the block below 
  # and run `terraform init -migrate-state`.
  backend "s3" {
    bucket         = "platform-tf-state-shared-f3ddb8cc"
    key            = "shared-services/us-east-2/prod/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "platform-tf-lock-table"
    encrypt        = true
    profile        = "AWS-hatan4ik-gmail"
  }
}

provider "aws" {
  profile = "AWS-hatan4ik-gmail"
  region = "us-east-2"
}

