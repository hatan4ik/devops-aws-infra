output "policy_arns" {
  description = "Terraform-owned sandbox delivery IAM policy ARNs."
  value       = module.sandbox_delivery_iam.policy_arns
}

output "role_arns" {
  description = "Existing GitHub OIDC role ARNs receiving Terraform-owned policies."
  value       = module.sandbox_delivery_iam.role_arns
}

output "github_oidc_provider_arn" {
  description = "Terraform-owned GitHub Actions OIDC provider ARN."
  value       = module.sandbox_delivery_iam.github_oidc_provider_arn
}
