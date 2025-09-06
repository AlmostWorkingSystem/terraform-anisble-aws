output "instance_public_ips" {
  description = "Public IPs of all created EC2 instances"
  value       = [for inst in module.aws_instance : inst.public_ip]
}

# output "instance_ids" {
#   description = "IDs of all created EC2 instances"
#   value       = [for inst in module.aws_instance : inst]
# }
# Output all bucket names
output "s3_bucket_names" {
  description = "Map of all S3 bucket names"
  value       = { for k, m in module.s3_buckets : k => m.bucket_name }
}

# Output all bucket ARNs
output "s3_bucket_arns" {
  description = "Map of all S3 bucket ARNs"
  value       = { for k, m in module.s3_buckets : k => m.bucket_arn }
}

# Output all IAM user names
output "iam_user_names" {
  description = "Map of all IAM user names for S3 access"
  value       = { for k, m in module.s3_users : k => m.user_name }
}

# Output all IAM access keys
output "iam_access_keys" {
  description = "Map of IAM access key IDs for each user"
  value       = { for k, m in module.s3_users : k => m.access_key_id }
  sensitive   = true
}

# Output all IAM secret keys
output "iam_secret_keys" {
  description = "Map of IAM secret access keys for each user"
  value       = { for k, m in module.s3_users : k => m.secret_access_key }
  sensitive   = true
}



output "s3_bucket_name" {
  description = "Name of the S3 bucket for OpenProject attachments"
  value       = module.attachments_bucket.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for OpenProject attachments"
  value       = module.attachments_bucket.bucket_arn
}

output "iam_user_name" {
  description = "IAM user created for OpenProject"
  value       = module.openproject_user.user_name
}

output "iam_access_key_id" {
  description = "Access key ID for the OpenProject IAM user (if created)"
  value       = module.openproject_user.access_key_id
  sensitive   = true
}

output "iam_secret_access_key" {
  description = "Secret access key for the OpenProject IAM user (if created)"
  value       = module.openproject_user.secret_access_key
  sensitive   = true
}
