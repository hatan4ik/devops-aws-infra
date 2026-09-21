# Non-secret, approved Organization control-plane contract. Account emails are
# intentionally absent: Terraform vends no account until an explicit account
# map is reviewed and merged.
aws_region            = "us-east-2"
management_account_id = "915507704945"
organization_id       = "o-94zz9kms7u"

organizational_units = [
  "Security",
  "Platform",
  "Workloads-Production",
  "Workloads-NonProduction",
  "Sandbox",
  "Suspended",
]

allowed_regions = [
  "us-east-1",
  "us-east-2",
  "us-west-2",
]

accounts = {}

tags = {
  Application = "platform"
  CostCenter  = "platform-bootstrap"
  Owner       = "hatan4ik"
}
