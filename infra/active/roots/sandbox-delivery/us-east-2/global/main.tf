module "sandbox_delivery_iam" {
  source = "git::https://github.com/hatan4ik/aws.modules.iam.git?ref=f529b69e6fc6d58842e7c3ba3a78540e457551c5" # v0.1.10

  aws_account_id          = var.aws_account_id
  aws_region              = var.aws_region
  role_prefix             = var.role_prefix
  github_subject_prefix   = var.github_subject_prefix
  github_oidc_thumbprints = var.github_oidc_thumbprints
  image_publishers        = var.image_publishers
  state_backend           = var.state_backend
}
