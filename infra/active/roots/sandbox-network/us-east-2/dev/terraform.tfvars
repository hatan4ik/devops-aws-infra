aws_region     = "us-east-2"
aws_account_id = "448871779014"
environment    = "dev"
network_name   = "sandbox-network-dev"
vpc_cidr       = "10.64.0.0/16"

# Confirmed by read-only AWS CLI preflight in the sandbox account on 2026-09-20.
availability_zones = {
  az1 = "us-east-2a"
  az2 = "us-east-2b"
}

private_subnet_cidrs = {
  az1 = "10.64.0.0/20"
  az2 = "10.64.16.0/20"
}

flow_log_retention_in_days = 365

tags = {
  Application = "platform"
  CostCenter  = "platform-bootstrap"
  Owner       = "hatan4ik"
}
