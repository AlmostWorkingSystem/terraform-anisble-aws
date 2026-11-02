#################################### cloudfront start ####################################
# Attachment CDNs. Synced from live AWS on 2 November 2026:
#   prod    E34Z198JLZGRUV  cdn.kiet.co.in          -> kiet-erp3-attachments-prod
#   staging E3DGPWQ0YF8I4A  cdn.staging.kiet.co.in  -> erp3-attachments
# S3 is read through Origin Access Control (OAC). Paths marked signed = true need a
# CloudFront signed URL (trusted key group); every other path is served to anyone.

locals {
  # Order matters: CloudFront uses the first matching path, then the default behaviour.
  cdn_paths_prod = [
    { path = "/users/*/PROVISIONAL_OFFER_LETTER/*", signed = true },
    { path = "/users/*/ORGANIZATION_DOCUMENT/*", signed = false },
    { path = "/users/*/BULK_EMPLOYEE_IMPORT/*", signed = false },
    { path = "/users/*/ORGANIZATION_MEDIA/*", signed = false },
    { path = "/users/*/PERSONAL_DOCUMENT/*", signed = true },
    { path = "/users/*/BULK_IMPORT_FILE/*", signed = true },
    { path = "/users/*/SIGNATURE_IMAGE/*", signed = false },
    { path = "/users/*/PROFILE_IMAGE/*", signed = false },
    { path = "/users/*/EXPORTED_FILE/*", signed = true },
    { path = "/users/*/FEE_RECEIPT/*", signed = true },
    { path = "assets/*", signed = false },
  ]

  cdn_paths_staging = [
    { path = "/users/*/ATTENDANCE_REQUEST_DOCUMENT/*", signed = true },
    { path = "/users/*/QUESTION_PAPER_ATTACHMENT/*", signed = true },
    { path = "/users/*/PROVISIONAL_OFFER_LETTER/*", signed = true },
    { path = "/users/*/REGISTRATION_PREVIEW_PDF/*", signed = true },
    { path = "/users/*/ORGANIZATION_DOCUMENT/*", signed = false },
    { path = "/users/*/EMPLOYEE_MEDICAL_CARD/*", signed = true },
    { path = "/users/*/BULK_EMPLOYEE_IMPORT/*", signed = false },
    { path = "/users/*/SCANNED_ANSWER_SHEET/*", signed = true },
    { path = "/users/*/IMPORT_MEDICAL_CARD/*", signed = true },
    { path = "/users/*/ORGANIZATION_MEDIA/*", signed = false },
    { path = "/users/*/EMPLOYEE_FORM_16_A/*", signed = true },
    { path = "/users/*/EMPLOYEE_FORM_16_B/*", signed = true },
    { path = "/users/*/PERSONAL_DOCUMENT/*", signed = true },
    { path = "/users/*/COURSE_BASKET_PDF/*", signed = true },
    { path = "/users/*/BULK_IMPORT_FILE/*", signed = true },
    { path = "/users/*/EMPLOYEE_PAYSLIP/*", signed = true },
    { path = "/users/*/SIGNATURE_IMAGE/*", signed = false },
    { path = "/users/*/IMPORT_FORM_16/*", signed = true },
    { path = "/users/*/PROFILE_IMAGE/*", signed = false },
    { path = "/users/*/EXPORTED_FILE/*", signed = true },
    { path = "/users/*/MODULE_MANUAL/*", signed = false },
    { path = "/users/*/FORM_BUILDER/*", signed = true },
    { path = "/users/*/FEE_RECEIPT/*", signed = true },
    { path = "assets/*", signed = false },
  ]

  # AWS managed policies
  cache_policy_caching_optimized = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  cache_policy_caching_disabled  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  # Managed-CORS-With-Preflight
  response_headers_policy_cors_preflight = "60669652-455b-4ae9-85a4-c4c02393f86c"

  # One-click WAF that CloudFront created; not managed here
  cdn_prod_web_acl_arn = "arn:aws:wafv2:us-east-1:029930584218:global/webacl/CreatedByCloudFront-95e90067/933dfcbe-7508-4617-869a-f620e90fe8ba"
}

# ACM certificates for CloudFront (must be in us-east-1). DNS validation records live in Cloudflare.
resource "aws_acm_certificate" "cdn_cert" {
  provider          = aws.us_east_1
  domain_name       = "cdn.kiet.co.in"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "cdn_cert_staging" {
  provider          = aws.us_east_1
  domain_name       = "cdn.staging.kiet.co.in"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_origin_access_control" "prod" {
  name                              = "kiet-erp3-attachments-prod.s3.ap-south-2.amazonaws.com"
  description                       = "PROD OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "staging" {
  name                              = "erp3-attachments.s3.ap-south-2.amazonaws.com"
  description                       = ""
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Legacy OAIs: no distribution uses them since the move to OAC. Safe to delete later.
resource "aws_cloudfront_origin_access_identity" "prod" {
  comment = "OAI for kiet-erp3-attachments-prod"
}

resource "aws_cloudfront_origin_access_identity" "staging" {
  comment = "OAI for erp3-attachments"
}

# Signed-URL keys. The private halves live with the backend, not here.
resource "aws_cloudfront_public_key" "prod" {
  name        = "PROD_ERP3_ATTACHMENTS_CLOUDFRONT_PUBLIC_KEY"
  comment     = "PROD_ERP3_ATTACHMENTS_CLOUDFRONT_PUBLIC_KEY"
  encoded_key = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8EmpnfD+YBjwdQ0ABVdR\ns8WpRMsLDbRsGtx4EikAjxxhC5fQnC7fNudOcVgdYPMFP6KVl46Kfgtk++gJ/icf\nMjCGOkY25x7tWLYI0p4VglOvSsAKU9OVmDvTDO5Oe7LWC8YfcV7YKKrsYLHWCR8s\nFF3rhPC51nfXEebCJUi0lOpZmP/J13xeMba4MFz8tj2H3X6M0zcBlPa61dUnZxYD\nxp3yl5G7UK+6DNuP//lCIetRk+M1S7m7PzJIJhIQ5UyOShINmX3zq0r4/PQJq/dH\nmXrnaSvhFOB5RoHVET6blbHvokYFkKvZqqaYMtVmPn+d++8vKZMdZhlUj32EgwdH\nUQIDAQAB\n-----END PUBLIC KEY-----\n"
}

resource "aws_cloudfront_public_key" "staging" {
  name        = "erp3_attachments_cloudfront_public_key"
  encoded_key = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyaciQHLvkmHF2WOdPM5k\n+VNdtYmpocZkYuQ+7J4OP/3I2XHRruFB+vjqif7TTdW/oWDwivMcJD1yAEQEvOud\nlAPYpjXb278E0wTrwmtFovqpUvDEZfKVocBbIACthIDrIdWkUWgzavQKep2WTMQO\nFfAM1APVWoSbt1ysXhXyYixYU1pDmXvQ1lsDH6m+Geeao0r+Yr92NFGlfscwhr32\nj4F+lPIron/aM5URhhFXROzYIZS8mtFUPkxdp6yTwGmeZGWvSG8VnZ1fX45tniFg\njFGBvnU/bg4osGCG4aE9HVzwz3ADwPWGl3S7SCHc26nzHDO+A2KDKGzfYCTdgPke\nuwIDAQAB\n-----END PUBLIC KEY-----\n"
}

resource "aws_cloudfront_key_group" "prod" {
  name    = "PROD_ERP3_CLOUDFRONT_KEY_GROUP"
  comment = "PROD_ERP3_CLOUDFRONT_KEY_GROUP"
  items   = [aws_cloudfront_public_key.prod.id]
}

resource "aws_cloudfront_key_group" "staging" {
  name  = "erp3_attachments_cloudfront"
  items = [aws_cloudfront_public_key.staging.id]
}

resource "aws_cloudfront_distribution" "prod" {
  enabled         = true
  comment         = "CloudFront CDN for ERP3 attachments (images)"
  aliases         = ["cdn.kiet.co.in"]
  price_class     = "PriceClass_200"
  http_version    = "http2and3"
  is_ipv6_enabled = false
  web_acl_id      = local.cdn_prod_web_acl_arn

  origin {
    origin_id                = "S3-kiet-erp3-attachments-prod"
    domain_name              = module.s3_buckets["kiet-erp3-attachments-prod"].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.prod.id

    origin_shield {
      enabled              = true
      origin_shield_region = "ap-south-1"
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3-kiet-erp3-attachments-prod"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400   # 1 day
    max_ttl                = 2592000 # 30 days

    forwarded_values {
      query_string = false
      headers      = ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"]

      cookies {
        forward = "none"
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.cdn_paths_prod
    content {
      path_pattern           = ordered_cache_behavior.value.path
      target_origin_id       = "S3-kiet-erp3-attachments-prod"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true
      viewer_protocol_policy = "redirect-to-https"
      cache_policy_id        = local.cache_policy_caching_optimized
      trusted_key_groups     = ordered_cache_behavior.value.signed ? [aws_cloudfront_key_group.prod.id] : []
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cdn_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "kiet-erp3-attachments-prod-cdn"
    Environment = "production"
    Purpose     = "Image caching for ERP3"
  }
}

resource "aws_cloudfront_distribution" "staging" {
  enabled         = true
  comment         = "CloudFront CDN for ERP3 attachments (images)"
  aliases         = ["cdn.staging.kiet.co.in"]
  price_class     = "PriceClass_200"
  http_version    = "http2and3"
  is_ipv6_enabled = false

  origin {
    origin_id                = "S3-erp3-attachments"
    domain_name              = module.s3_buckets["erp3-attachments"].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.staging.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-erp3-attachments"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = local.cache_policy_caching_disabled
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.cdn_paths_staging
    content {
      path_pattern               = ordered_cache_behavior.value.path
      target_origin_id           = "S3-erp3-attachments"
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      viewer_protocol_policy     = "redirect-to-https"
      cache_policy_id            = local.cache_policy_caching_optimized
      response_headers_policy_id = local.response_headers_policy_cors_preflight
      trusted_key_groups         = ordered_cache_behavior.value.signed ? [aws_cloudfront_key_group.staging.id] : []
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cdn_cert_staging.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "erp3-attachments-dev-cdn"
    Environment = "development"
    Purpose     = "Image caching for ERP3"
  }
}

# Each bucket is readable only by its own distribution (OAC)
locals {
  cdn_bucket_distribution = {
    "kiet-erp3-attachments-prod" = aws_cloudfront_distribution.prod.arn
    "erp3-attachments"           = aws_cloudfront_distribution.staging.arn
  }
}

resource "aws_s3_bucket_policy" "cdn_read" {
  for_each = local.cdn_bucket_distribution
  bucket   = module.s3_buckets[each.key].bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAssetsCloudFrontRead"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${module.s3_buckets[each.key].bucket_arn}/*"
      Condition = { StringEquals = { "AWS:SourceArn" = each.value } }
    }]
  })
}

# Same CORS rules on both buckets: browser uploads (PUT) and range reads
resource "aws_s3_bucket_cors_configuration" "attachments" {
  for_each = local.cdn_bucket_distribution
  bucket   = module.s3_buckets[each.key].bucket_name

  cors_rule {
    allowed_headers = ["content-type", "content-disposition"]
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag", "x-amz-request-id"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_headers = ["range", "if-modified-since", "if-none-match"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["Accept-Ranges", "Content-Range", "Content-Length", "Content-Encoding", "ETag"]
    max_age_seconds = 3000
  }
}

# State addresses from the old ./modules/cloudfront module
moved {
  from = module.erp3_attachments_cloudfront_prod.aws_cloudfront_origin_access_identity.this
  to   = aws_cloudfront_origin_access_identity.prod
}
moved {
  from = module.erp3_attachments_cloudfront.aws_cloudfront_origin_access_identity.this
  to   = aws_cloudfront_origin_access_identity.staging
}
moved {
  from = module.erp3_attachments_cloudfront_prod.aws_s3_bucket_policy.cloudfront_access
  to   = aws_s3_bucket_policy.cdn_read["kiet-erp3-attachments-prod"]
}
moved {
  from = module.erp3_attachments_cloudfront.aws_s3_bucket_policy.cloudfront_access
  to   = aws_s3_bucket_policy.cdn_read["erp3-attachments"]
}
#################################### cloudfront end ####################################
