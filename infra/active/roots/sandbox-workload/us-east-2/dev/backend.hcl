# Unique, non-secret remote-state configuration for private sandbox workloads.
bucket         = "platform-tf-state-shared-f3ddb8cc"
key            = "gitops/sandbox-workload/us-east-2/dev/terraform.tfstate"
region         = "us-east-2"
dynamodb_table = "platform-tf-lock-table"
encrypt        = true
kms_key_id     = "arn:aws:kms:us-east-2:448871779014:key/34605b23-fafd-43f8-b708-db4dbe385189"
