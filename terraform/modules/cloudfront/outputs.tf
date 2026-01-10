output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront Route 53 zone ID"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "origin_access_identity_iam_arn" {
  description = "IAM ARN of the CloudFront origin access identity"
  value       = aws_cloudfront_origin_access_identity.this.iam_arn
}

output "origin_access_identity_path" {
  description = "CloudFront origin access identity path"
  value       = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
}
