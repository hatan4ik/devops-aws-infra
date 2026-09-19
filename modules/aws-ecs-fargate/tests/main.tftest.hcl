mock_provider "aws" {}

run "valid_configuration" {
  command = plan

  variables {
    config = {
      cluster_name = "test-cluster"
      environment  = "dev"
    }
  }

  assert {
    condition     = aws_ecs_cluster.this.name == "test-cluster"
    error_message = "Cluster name mismatch."
  }
}
