resource "aws_kms_key" "state" {
  for_each = var.state_tiers

  description             = "Terraform state encryption key for ${each.key}"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  policy                  = local.state_key_policies[each.key]

  tags = merge(local.common_tags, {
    Name            = "${var.name_prefix}-${each.key}-terraform-state"
    EnvironmentTier = each.key
  })
}

resource "aws_kms_alias" "state" {
  for_each = var.state_tiers

  name          = "alias/${var.name_prefix}-${each.key}-terraform-state"
  target_key_id = aws_kms_key.state[each.key].key_id
}

resource "aws_s3_bucket" "state" {
  for_each = var.state_tiers

  bucket              = each.value.bucket_name
  object_lock_enabled = each.value.object_lock.enabled

  tags = merge(local.common_tags, {
    Name            = each.value.bucket_name
    EnvironmentTier = each.key
  })
}

resource "aws_s3_bucket_public_access_block" "state" {
  for_each = var.state_tiers

  bucket                  = aws_s3_bucket.state[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  for_each = var.state_tiers

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  for_each = var.state_tiers

  bucket = aws_s3_bucket.state[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  for_each = var.state_tiers

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state[each.key].arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  for_each = var.state_tiers

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    id     = "retain-current-state-expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = each.value.noncurrent_version_expiration_in_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = each.value.abort_incomplete_multipart_upload_after_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

resource "aws_s3_bucket_object_lock_configuration" "state" {
  for_each = {
    for tier, configuration in var.state_tiers : tier => configuration
    if configuration.object_lock.enabled
  }

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    default_retention {
      mode = each.value.object_lock.retention_mode
      days = each.value.object_lock.retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

resource "aws_s3_bucket_policy" "state" {
  for_each = var.state_tiers

  bucket = aws_s3_bucket.state[each.key].id
  policy = local.state_bucket_policies[each.key]

  depends_on = [aws_s3_bucket_public_access_block.state]
}

resource "aws_dynamodb_table" "state_lock" {
  for_each = var.state_tiers

  name         = local.state_lock_table_names[each.key]
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state[each.key].arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name            = local.state_lock_table_names[each.key]
    EnvironmentTier = each.key
  })
}
