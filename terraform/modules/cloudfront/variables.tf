variable "bucket_name" {
  description = "Name of the S3 bucket to use as CloudFront origin"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "distribution_comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
  default     = "CloudFront distribution for S3 bucket"
}

variable "price_class" {
  description = "Price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_200" # Use only North America and Europe edge locations
}

variable "enabled" {
  description = "Whether the distribution is enabled"
  type        = bool
  default     = true
}

variable "default_ttl" {
  description = "Default TTL for cached objects (in seconds)"
  type        = number
  default     = 86400 # 1 day
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects (in seconds)"
  type        = number
  default     = 31536000 # 1 year
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects (in seconds)"
  type        = number
  default     = 0
}

variable "allowed_methods" {
  description = "HTTP methods that CloudFront processes and forwards to the S3 bucket"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "cached_methods" {
  description = "HTTP methods for which CloudFront caches responses"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "compress" {
  description = "Whether CloudFront automatically compresses content"
  type        = bool
  default     = true
}

variable "viewer_protocol_policy" {
  description = "Protocol policy for viewers (allow-all, https-only, redirect-to-https)"
  type        = string
  default     = "redirect-to-https"
}

variable "tags" {
  description = "Tags to apply to CloudFront distribution"
  type        = map(string)
  default     = {}
}
