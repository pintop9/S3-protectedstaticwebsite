terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
  }
}

provider "aws" {
  region                   = "il-central-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

provider "aws" {
  alias                    = "us_east_1"
  region                   = "us-east-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

# S3 Bucket for the static website
resource "aws_s3_bucket" "static_website_for_S3" {
  bucket = "s3-static-website-project-${random_string.suffix.result}"  
  force_destroy = true
}

# Generate random suffix for bucket name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_website_for_S3.id

  index_document {
    suffix = "index.html"
  }
}

# Configure public access block
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_website_for_S3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add bucket policy to allow public read
resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website_for_S3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_website_for_S3.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public_access_block]
}

locals {
  files_to_upload = {
    "index.html" = "text/html"
    "Scripts/scripts.js" = "application/javascript"
    "Styles/style.css" = "text/css"
    "Images/favicon.png" = "image/png"
  }
}

resource "aws_s3_object" "website_files" {
  for_each = local.files_to_upload

  bucket = aws_s3_bucket.static_website_for_S3.id
  key    = each.key
  source = each.key
  etag   = filemd5(each.key)
  content_type = each.value

  depends_on = [aws_s3_bucket_policy.static_website_policy]
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Access Identity for S3 Bucket"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_website_for_S3.bucket_regional_domain_name
    origin_id   = "S3-my-static-website"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-my-static-website"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    compress               = true
    smooth_streaming       = false
  }

  # Update the custom error response to handle 403s
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  # WAF Web ACL Association
  web_acl_id = aws_wafv2_web_acl.waf.arn

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  depends_on = [aws_s3_object.website_files]
}

locals {
  invalidation_trigger = md5(jsonencode([
    for s3_object in aws_s3_object.website_files : {
      etag = s3_object.etag
    }
  ]))
}

resource "null_resource" "cloudfront_invalidation" {
  triggers = {
    invalidation_trigger = local.invalidation_trigger
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.cdn.id} --paths /"
  }

  depends_on = [aws_cloudfront_distribution.cdn]
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "waf" {
  provider    = aws.us_east_1
  name        = "my-waf-acl"
  description = "WAF ACL for protecting CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimitMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "waf_acl"
    sampled_requests_enabled  = true
  }
}

# Output the S3 website endpoint URL
output "s3_website_endpoint" {
  value = "http://${aws_s3_bucket.static_website_for_S3.bucket_regional_domain_name}"
}

# Output the CloudFront URL
output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

# Output the CloudFront distribution ID
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}
