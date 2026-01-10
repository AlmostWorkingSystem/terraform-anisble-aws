# Origin Access Identity for CloudFront to access S3
resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for ${var.bucket_name}"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  comment             = var.distribution_comment
  price_class         = var.price_class
  default_root_object = ""

  origin {
    domain_name = var.bucket_regional_domain_name
    origin_id   = "S3-${var.bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    target_origin_id       = "S3-${var.bucket_name}"
    compress               = var.compress
    viewer_protocol_policy = var.viewer_protocol_policy

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  # Cache behavior for images with optimized settings
  ordered_cache_behavior {
    path_pattern           = "*.jpg"
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    target_origin_id       = "S3-${var.bucket_name}"
    compress               = var.compress
    viewer_protocol_policy = var.viewer_protocol_policy

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  ordered_cache_behavior {
    path_pattern           = "*.jpeg"
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    target_origin_id       = "S3-${var.bucket_name}"
    compress               = var.compress
    viewer_protocol_policy = var.viewer_protocol_policy

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  ordered_cache_behavior {
    path_pattern           = "*.png"
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    target_origin_id       = "S3-${var.bucket_name}"
    compress               = var.compress
    viewer_protocol_policy = var.viewer_protocol_policy

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  ordered_cache_behavior {
    path_pattern           = "*.gif"
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    target_origin_id       = "S3-${var.bucket_name}"
    compress               = var.compress
    viewer_protocol_policy = var.viewer_protocol_policy

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  ordered_cache_behavior {
    path_pattern           = "*.webp"
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    target_origin_id       = "S3-${var.bucket_name}"
    compress               = var.compress
    viewer_protocol_policy = var.viewer_protocol_policy

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  ordered_cache_behavior {
    path_pattern           = "*.svg"
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    target_origin_id       = "S3-${var.bucket_name}"
    compress               = var.compress
    viewer_protocol_policy = var.viewer_protocol_policy

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# S3 Bucket Policy to allow CloudFront OAI to read from the bucket
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = var.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.this.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${var.bucket_arn}/*"
      }
    ]
  })
}
