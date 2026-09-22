# Immutable, non-secret contract for the Terraform-owned sandbox delivery IAM.
aws_region              = "us-east-2"
aws_account_id          = "448871779014"
role_prefix             = "devops-aws-infra-sandbox"
github_subject_prefix   = "repo:hatan4ik@12816536/devops-aws-infra@1375932356"
github_oidc_thumbprints = ["ab9d0263244dd0326eb67015705a667e79cfe998"]

state_backend = {
  bucket_name     = "platform-tf-state-shared-f3ddb8cc"
  key_prefix      = "gitops/sandbox-delivery/us-east-2/global/"
  kms_key_id      = "34605b23-fafd-43f8-b708-db4dbe385189"
  lock_table_name = "platform-tf-lock-table"
}
