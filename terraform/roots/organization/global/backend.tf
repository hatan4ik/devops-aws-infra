terraform {
  # GitHub Actions writes reviewed, non-secret backend values at runtime from
  # repository variables set by the versioned bootstrap script.
  backend "s3" {}
}
