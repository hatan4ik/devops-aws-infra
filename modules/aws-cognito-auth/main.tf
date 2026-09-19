locals {
  common_tags = merge(
    var.config.tags,
    {
      Environment = var.config.environment
      ManagedBy   = "Terraform"
      Module      = "aws-cognito-auth"
    }
  )
}

resource "aws_cognito_user_pool" "this" {
  name = var.config.pool_name

  mfa_configuration = var.config.enable_mfa

  password_policy {
    minimum_length                   = var.config.minimum_password_length
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  user_pool_add_ons {
    advanced_security_mode = var.config.advanced_security_mode
  }

  # Ensure emails are verified
  auto_verified_attributes = ["email"]

  # Standard attributes
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true
  }

  software_token_mfa_configuration {
    enabled = var.config.enable_mfa != "OFF" ? true : false
  }

  tags = local.common_tags
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${var.config.domain_prefix}-${var.config.environment}"
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "${var.config.pool_name}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = true

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.config.callback_urls
  logout_urls                          = var.config.logout_urls
  supported_identity_providers         = ["COGNITO"]
}

