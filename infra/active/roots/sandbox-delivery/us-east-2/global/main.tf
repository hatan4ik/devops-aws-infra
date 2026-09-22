module "sandbox_delivery_iam" {
  source = "git::https://github.com/hatan4ik/aws.modules.iam.git?ref=4722b8b670e4b0b3127581bf6b6d126e365e6b7e" # v0.1.9

  aws_account_id          = var.aws_account_id
  aws_region              = var.aws_region
  role_prefix             = var.role_prefix
  github_subject_prefix   = var.github_subject_prefix
  github_oidc_thumbprints = var.github_oidc_thumbprints
  image_publishers        = var.image_publishers
  state_backend           = var.state_backend
}
