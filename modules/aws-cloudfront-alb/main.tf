locals {
  common_tags = merge(
    var.config.tags,
    {
      Environment = var.config.environment
      ManagedBy   = "Terraform"
      Module      = "aws-cloudfront-alb"
    }
  )
}

# Example WAF implementation (basic IP rate limiting)
resource "aws_wafv2_web_acl" "this" {
  count       = var.config.enable_waf ? 1 : 0
  name        = "${var.config.name}-waf"
  description = "Basic WAF for CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 5000 # 5000 requests per 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.config.name}-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Managed by Terraform"
  web_acl_id          = var.config.enable_waf ? aws_wafv2_web_acl.this[0].arn : null
  price_class         = "PriceClass_100"

  origin {
    domain_name = var.config.primary_alb_domain
    origin_id   = "primary-alb"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  dynamic "origin" {
    for_each = var.config.secondary_alb_domain != "" ? [1] : []
    content {
      domain_name = var.config.secondary_alb_domain
      origin_id   = "secondary-alb"
      
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Active-Active failover Origin Group (ADR 0002 / ADR 0006)
  dynamic "origin_group" {
    for_each = var.config.secondary_alb_domain != "" ? [1] : []
    content {
      origin_id = "active-active-group"
      
      failover_criteria {
        status_codes = [500, 502, 503, 504]
      }

      member {
        origin_id = "primary-alb"
      }
      member {
        origin_id = "secondary-alb"
      }
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.config.secondary_alb_domain != "" ? "active-active-group" : "primary-alb"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

