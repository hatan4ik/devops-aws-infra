terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }

  backend "s3" {
    bucket         = "platform-tf-state-workload" # Update dynamically in real deploy
    key            = "workload-app/us-east-2/prod/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "platform-tf-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}
