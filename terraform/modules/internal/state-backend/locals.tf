locals {
  # Terraform's S3 backend supports a lockfile; DynamoDB locking stays here during its documented migration period to meet the platform requirement.
  state_lock_table_names = {
    for tier in keys(var.state_tiers) : tier => "${var.name_prefix}-${tier}-terraform-locks"
  }

  common_tags = merge(var.tags, {
    Component = "terraform-state"
  })

  state_key_policies = {
    for tier in keys(var.state_tiers) : tier => jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "KeyAdministration"
          Effect = "Allow"
          Action = [
            "kms:Create*",
            "kms:Describe*",
            "kms:Enable*",
            "kms:Get*",
            "kms:List*",
            "kms:Put*",
            "kms:Revoke*",
            "kms:Update*",
            "kms:Disable*",
            "kms:Delete*",
            "kms:TagResource",
            "kms:UntagResource",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion",
          ]
          Resource  = "*"
          Principal = { AWS = tolist(var.key_administrator_arns) }
        },
        {
          Sid = "StateEncryptionUse"
          Action = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey*",
            "kms:ReEncrypt*",
          ]
          Effect    = "Allow"
          Resource  = "*"
          Principal = { AWS = tolist(var.state_access_principal_arns) }
        },
      ]
    })
  }

  state_bucket_policies = {
    for tier in keys(var.state_tiers) : tier => jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "DenyInsecureTransport"
          Effect    = "Deny"
          Action    = "s3:*"
          Resource  = [aws_s3_bucket.state[tier].arn, "${aws_s3_bucket.state[tier].arn}/*"]
          Principal = "*"
          Condition = { Bool = { "aws:SecureTransport" = "false" } }
        },
        {
          Sid       = "DenyPrincipalsOutsideStateRoles"
          Effect    = "Deny"
          Action    = "s3:*"
          Resource  = [aws_s3_bucket.state[tier].arn, "${aws_s3_bucket.state[tier].arn}/*"]
          Principal = "*"
          Condition = { ArnNotEquals = { "aws:PrincipalArn" = tolist(var.state_access_principal_arns) } }
        },
        {
          Sid       = "AllowStateBucketMetadata"
          Effect    = "Allow"
          Action    = ["s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:ListBucket"]
          Resource  = aws_s3_bucket.state[tier].arn
          Principal = { AWS = tolist(var.state_access_principal_arns) }
        },
        {
          Sid       = "AllowStateAndLockObjects"
          Effect    = "Allow"
          Action    = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
          Resource  = "${aws_s3_bucket.state[tier].arn}/*"
          Principal = { AWS = tolist(var.state_access_principal_arns) }
        },
      ]
    })
  }
}
