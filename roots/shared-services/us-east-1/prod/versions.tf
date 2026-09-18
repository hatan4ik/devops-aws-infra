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
  /*
  backend "s3" {
    bucket         = "ses-tf-state-shared-<random>" # Update with actual generated bucket name
    key            = "shared-services/us-east-1/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ses-tf-lock-table"
    encrypt        = true
  }
  */
}

provider "aws" {
  region = "us-east-1"
}

