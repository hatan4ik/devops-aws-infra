locals {
  common_tags = merge(
    var.config.tags,
    {
      Environment = var.config.environment
      ManagedBy   = "Terraform"
      Module      = "aws-ecs-fargate"
    }
  )
}

resource "aws_ecs_cluster" "this" {
  name = var.config.cluster_name

  setting {
    name  = "containerInsights"
    value = var.config.enable_container_insights ? "enhanced" : "disabled"
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
