output "instance_public_ips" {
  description = "Public IPs of all created EC2 instances"
  value       = [for inst in module.aws_instance : inst.public_ip]
}

output "instance_ids" {
  description = "IDs of all created EC2 instances"
  value       = [for inst in module.aws_instance : inst]
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
