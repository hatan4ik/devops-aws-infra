# This module represents the observed bootstrap exactly enough to move its
# existing Terraform bindings into the canonical tree. It deliberately does
# not introduce the future multi-Region state design; ADR 0015 requires that
# to be a separately reviewed hardening migration after adoption is complete.

resource "aws_kms_key" "state" {
  description             = var.config.kms_key_description
  deletion_window_in_days = var.config.kms_key_deletion_window_in_days
  enable_key_rotation     = true
  multi_region            = false
  tags                    = var.config.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "state" {
  name          = var.config.kms_key_alias
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_s3_bucket" "state" {
  bucket              = var.config.bucket_name
  object_lock_enabled = true
  tags                = var.config.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
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

resource "aws_s3_bucket_object_lock_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    default_retention {
      mode = var.config.object_lock_retention_mode
      days = var.config.object_lock_retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

resource "aws_dynamodb_table" "state_lock" {
  name                        = var.config.dynamodb_table_name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "LockID"
  deletion_protection_enabled = var.config.dynamodb_deletion_protection_enabled

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

  tags = var.config.tags

  lifecycle {
    prevent_destroy = true
  }
}
