# Unique, non-secret remote-state configuration for sandbox delivery IAM.
bucket         = "platform-tf-state-shared-f3ddb8cc"
key            = "gitops/sandbox-delivery/us-east-2/global/terraform.tfstate"
region         = "us-east-2"
dynamodb_table = "platform-tf-lock-table"
encrypt        = true
