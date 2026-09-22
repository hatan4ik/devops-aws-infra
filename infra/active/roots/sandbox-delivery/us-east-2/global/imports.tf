# These imports adopt CloudFormation-created policies and attachments without
# replacing or detaching them. Terraform does not write the imports to state
# until the reviewed adoption plan is applied.
import {
  to = module.sandbox_delivery_iam.aws_iam_policy.sandbox_network_plan
  id = "arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-network-plan"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_policy.sandbox_network_dev_apply
  id = "arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-network-dev-apply"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_policy.sandbox_platform_plan
  id = "arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-platform-plan"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_policy.sandbox_platform_dev_apply
  id = "arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-platform-dev-apply"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["network_plan_to_plan"]
  id = "${var.role_prefix}-plan/arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-network-plan"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["network_plan_to_drift"]
  id = "${var.role_prefix}-drift/arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-network-plan"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["network_apply_to_dev_apply"]
  id = "${var.role_prefix}-dev-apply/arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-network-dev-apply"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["platform_plan_to_plan"]
  id = "${var.role_prefix}-plan/arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-platform-plan"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["platform_plan_to_drift"]
  id = "${var.role_prefix}-drift/arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-platform-plan"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_role_policy_attachment.delivery["platform_apply_to_dev_apply"]
  id = "${var.role_prefix}-dev-apply/arn:aws:iam::${var.aws_account_id}:policy/${var.role_prefix}-sandbox-platform-dev-apply"
}

import {
  to = module.sandbox_delivery_iam.aws_iam_openid_connect_provider.github_actions
  id = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
}

import {
  for_each = toset(["plan", "dev_apply", "staging_apply", "prod_apply", "drift", "landing_zone"])
  to       = module.sandbox_delivery_iam.aws_iam_role.github_actions[each.key]
  id       = "${var.role_prefix}-${replace(each.key, "_", "-")}"
}
