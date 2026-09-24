# State moves for the aws.modules.vpc 0.1.x -> 1.0.0 upgrade. Every resource
# keeps its name, tags, and settings; the plan must show moves only. Remove
# this file once the upgrade has been applied everywhere.

moved {
  from = module.sandbox_network.aws_default_security_group.deny_all
  to   = module.sandbox_network.aws_default_security_group.this
}

moved {
  from = module.sandbox_network.aws_vpc_encryption_control.this
  to   = module.sandbox_network.aws_vpc_encryption_control.this[0]
}

moved {
  from = module.sandbox_network.aws_subnet.private["az1"]
  to   = module.sandbox_network.module.subnets["private"].aws_subnet.this["az1"]
}

moved {
  from = module.sandbox_network.aws_subnet.private["az2"]
  to   = module.sandbox_network.module.subnets["private"].aws_subnet.this["az2"]
}

moved {
  from = module.sandbox_network.aws_route_table.private["az1"]
  to   = module.sandbox_network.module.subnets["private"].aws_route_table.this["az1"]
}

moved {
  from = module.sandbox_network.aws_route_table.private["az2"]
  to   = module.sandbox_network.module.subnets["private"].aws_route_table.this["az2"]
}

moved {
  from = module.sandbox_network.aws_route_table_association.private["az1"]
  to   = module.sandbox_network.module.subnets["private"].aws_route_table_association.this["az1"]
}

moved {
  from = module.sandbox_network.aws_route_table_association.private["az2"]
  to   = module.sandbox_network.module.subnets["private"].aws_route_table_association.this["az2"]
}

moved {
  from = module.sandbox_network.aws_kms_key.flow_logs
  to   = module.sandbox_network.module.flow_logs[0].aws_kms_key.this[0]
}

moved {
  from = module.sandbox_network.aws_kms_alias.flow_logs
  to   = module.sandbox_network.module.flow_logs[0].aws_kms_alias.this[0]
}

moved {
  from = module.sandbox_network.aws_cloudwatch_log_group.flow_logs
  to   = module.sandbox_network.module.flow_logs[0].aws_cloudwatch_log_group.this[0]
}

moved {
  from = module.sandbox_network.aws_iam_role.flow_logs
  to   = module.sandbox_network.module.flow_logs[0].aws_iam_role.this[0]
}

moved {
  from = module.sandbox_network.aws_iam_role_policy.flow_logs_delivery
  to   = module.sandbox_network.module.flow_logs[0].aws_iam_role_policy.this[0]
}

moved {
  from = module.sandbox_network.aws_flow_log.vpc
  to   = module.sandbox_network.module.flow_logs[0].aws_flow_log.this
}
