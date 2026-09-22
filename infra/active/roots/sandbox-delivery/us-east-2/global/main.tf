module "sandbox_delivery_iam" {
  source = "git::https://github.com/hatan4ik/aws.modules.iam.git?ref=b2541419bb9be16667006bf614b08d6ef472ccb4" # v0.1.2

  aws_account_id          = var.aws_account_id
  aws_region              = var.aws_region
  role_prefix             = var.role_prefix
  github_subject_prefix   = var.github_subject_prefix
  github_oidc_thumbprints = var.github_oidc_thumbprints
  state_backend           = var.state_backend
}
