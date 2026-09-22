# This key is intentionally unique to the first sandbox network slice. It is
# non-secret immutable deployment configuration, not a local credential file.
bucket         = "platform-tf-state-shared-f3ddb8cc"
key            = "gitops/sandbox-network/us-east-2/dev/terraform.tfstate"
region         = "us-east-2"
dynamodb_table = "platform-tf-lock-table"
encrypt        = true
kms_key_id     = "arn:aws:kms:us-east-2:448871779014:key/34605b23-fafd-43f8-b708-db4dbe385189"
