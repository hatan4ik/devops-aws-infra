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
          Principal = { AWS = concat(tolist(var.state_access_principal_arns), [aws_iam_role.state_replication.arn]) }
        },
      ]
    })
  }

  state_replica_key_policies = {
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
          Sid = "StateReplicaEncryptionUse"
          Action = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey*",
            "kms:ReEncrypt*",
          ]
          Effect    = "Allow"
          Resource  = "*"
          Principal = { AWS = concat(tolist(var.state_access_principal_arns), [aws_iam_role.state_replication.arn]) }
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
          Condition = { ArnNotEquals = { "aws:PrincipalArn" = concat(tolist(var.state_access_principal_arns), [aws_iam_role.state_replication.arn]) } }
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

  state_replica_bucket_policies = {
    for tier in keys(var.state_tiers) : tier => jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "DenyInsecureTransport"
          Effect    = "Deny"
          Action    = "s3:*"
          Resource  = [aws_s3_bucket.state_replica[tier].arn, "${aws_s3_bucket.state_replica[tier].arn}/*"]
          Principal = "*"
          Condition = { Bool = { "aws:SecureTransport" = "false" } }
        },
        {
          Sid       = "DenyPrincipalsOutsideStateRecoveryAndReplicationRoles"
          Effect    = "Deny"
          Action    = "s3:*"
          Resource  = [aws_s3_bucket.state_replica[tier].arn, "${aws_s3_bucket.state_replica[tier].arn}/*"]
          Principal = "*"
          Condition = { ArnNotEquals = { "aws:PrincipalArn" = concat(tolist(var.state_access_principal_arns), [aws_iam_role.state_replication.arn]) } }
        },
        {
          Sid       = "AllowStateRecoveryBucketMetadata"
          Effect    = "Allow"
          Action    = ["s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:ListBucket"]
          Resource  = aws_s3_bucket.state_replica[tier].arn
          Principal = { AWS = tolist(var.state_access_principal_arns) }
        },
        {
          Sid       = "AllowReplicatedStateRecoveryObjects"
          Effect    = "Allow"
          Action    = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
          Resource  = "${aws_s3_bucket.state_replica[tier].arn}/*"
          Principal = { AWS = tolist(var.state_access_principal_arns) }
        },
      ]
    })
  }

  state_replication_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSourceBucketReplicationConfiguration"
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = [for bucket in values(aws_s3_bucket.state) : bucket.arn]
      },
      {
        Sid    = "ReadSourceObjectVersionsForReplication"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold",
        ]
        Resource = [for bucket in values(aws_s3_bucket.state) : "${bucket.arn}/*"]
      },
      {
        Sid    = "WriteReplicatedObjectVersions"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner",
        ]
        Resource = [for bucket in values(aws_s3_bucket.state_replica) : "${bucket.arn}/*"]
      },
      {
        Sid      = "DecryptPrimaryStateKeys"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = [for key in values(aws_kms_key.state) : key.arn]
      },
      {
        Sid      = "EncryptReplicaStateKeys"
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:GenerateDataKey"]
        Resource = [for key in values(aws_kms_replica_key.state) : key.arn]
      },
    ]
  })
}
