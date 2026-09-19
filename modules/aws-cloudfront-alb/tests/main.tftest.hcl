mock_provider "aws" {}

run "valid_configuration" {
  command = plan

  variables {
    config = {
      name               = "test-cf"
      environment        = "dev"
      primary_alb_domain = "alb1.example.com"
    }
  }

  assert {
    condition     = aws_cloudfront_distribution.this.enabled == true
    error_message = "Distribution should be enabled."
  }
}
