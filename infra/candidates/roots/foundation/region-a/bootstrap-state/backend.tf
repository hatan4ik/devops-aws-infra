terraform {
  # Configured only during the approved migration with an uncommitted backend
  # config file. Use `terraform init -backend=false` for static validation.
  backend "s3" {}
}
