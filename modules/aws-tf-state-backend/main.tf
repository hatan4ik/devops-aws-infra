locals {
  common_tags = merge(
    var.config.tags,
    {
      Environment = var.config.environment
      ManagedBy   = "Terraform"
      Module      = "aws-tf-state-backend"
    }
  )
}

# ------------------------------------------------------------------------------
# KMS Key for S3 Bucket Encryption
# ------------------------------------------------------------------------------
resource "aws_kms_key" "state" {
  description             = "KMS key for encrypting Terraform state bucket for ${var.config.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "state" {
  name          = var.config.kms_key_alias
  target_key_id = aws_kms_key.state.key_id
}

# ------------------------------------------------------------------------------
# S3 Bucket for State
# ------------------------------------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "state" {
  bucket = "${var.config.bucket_prefix}-${var.config.environment}-${random_id.bucket_suffix.hex}"
  tags   = local.common_tags

  # Protect against accidental destruction of the state bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable Object Lock as required by the brief (forces retention on versions)
resource "aws_s3_bucket_object_lock_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 14
    }
  }
}

# ------------------------------------------------------------------------------
# DynamoDB Table for State Locking
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "lock" {
  name         = var.config.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state.arn
  }

  tags = local.common_tags
}
