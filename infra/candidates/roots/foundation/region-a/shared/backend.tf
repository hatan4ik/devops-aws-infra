terraform {
  # Backend values are injected from the approved shared-services state-backend output after its one-time bootstrap.
  backend "s3" {}
}
