terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }

  backend "s3" {
    bucket         = "ses-tf-state-workload" # Update dynamically in real deploy
    key            = "workload-app/us-east-1/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ses-tf-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

