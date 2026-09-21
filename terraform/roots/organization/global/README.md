# Direct AWS Organizations root

This root creates only top-level OUs and baseline SCPs, then vends only the
accounts explicitly present in its reviewed `accounts` map. It deliberately
does not enable Control Tower, move the existing sandbox account, create a
VPN/BGP connection, or access member accounts.

The CloudFormation bootstrap at
[`bootstrap/management-organization-delivery-policy`](../../../../bootstrap/management-organization-delivery-policy/)
owns this root's KMS-encrypted S3 state bucket, DynamoDB lock table, and
least-privilege GitHub OIDC role policies. GitHub Actions is the only apply
path. Backend values are ephemeral runner configuration, not committed to this
directory.

Before adding an account to `terraform.tfvars`, obtain and review its unique
email address, owner, target OU, cost allocation, IPAM allocation, region
policy, and member-account baseline plan. Never infer an email alias or CIDR.
