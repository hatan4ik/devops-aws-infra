locals {
  default_tags = merge(tomap(var.tags), {
    ManagedBy   = "terraform"
    Repository  = "hatan4ik/devops-aws-infra"
    Root        = "organization"
    Environment = "shared"
  })

  policy_documents = {
    deny_organization_escape = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "DenyLeavingTheOrganization"
          Effect   = "Deny"
          Action   = "organizations:LeaveOrganization"
          Resource = "*"
        },
      ]
    })

    deny_unapproved_regions = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "DenyUnapprovedRegions"
          Effect = "Deny"
          NotAction = [
            "a4b:*",
            "acm:*",
            "aws-portal:*",
            "budgets:*",
            "ce:*",
            "chime:*",
            "cloudfront:*",
            "cur:*",
            "directconnect:*",
            "ec2:DescribeRegions",
            "ec2:DescribeTransitGateways",
            "ec2:DescribeVpnConnections",
            "fms:*",
            "globalaccelerator:*",
            "health:*",
            "iam:*",
            "importexport:*",
            "kms:*",
            "mobileanalytics:*",
            "networkmanager:*",
            "organizations:*",
            "pricing:*",
            "route53:*",
            "route53domains:*",
            "s3:GetAccountPublicAccessBlock",
            "s3:ListAllMyBuckets",
            "shield:*",
            "sts:*",
            "support:*",
            "tag:*",
            "trustedadvisor:*",
            "waf-regional:*",
            "waf:*",
            "wafv2:*"
          ]
          Resource = "*"
          Condition = {
            StringNotEquals = {
              "aws:RequestedRegion" = sort(tolist(var.allowed_regions))
            }
          }
        },
      ]
    })
  }
}
