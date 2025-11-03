# output "instance_public_ips" {
#   description = "Public IPs of all created EC2 instances"
#   value       = [for inst in module.aws_instance : inst.public_ip]
# }

output "instance_ips" {
  description = "Map of instance name → { private_ip, public_ip }"
  value = {
    for _, inst in module.aws_instance :
    inst.instance_name => {
      private_ip = inst.private_ip
      public_ip  = inst.public_ip
    }
  }
}

# output "instance_ids" {
#   description = "IDs of all created EC2 instances"
#   value       = [for inst in module.aws_instance : inst]
# }

output "ses_user_access_key" {
  description = "The access key ID for the SES user"
  value       = module.ses_user.access_key_id
  sensitive   = true
}

output "ses_user_secret_key" {
  description = "The secret access key for the SES user"
  value       = module.ses_user.secret_access_key
  sensitive   = true
}

# S3 start
output "s3_bucket_names" {
  description = "Map of all S3 bucket names"
  value       = { for k, m in module.s3_buckets : k => m.bucket_name }
}
output "s3_bucket_arns" {
  description = "Map of all S3 bucket ARNs"
  value       = { for k, m in module.s3_buckets : k => m.bucket_arn }
}
output "s3_iam_user_names" {
  description = "Map of all IAM user names for S3 access"
  value       = { for k, m in module.s3_users : k => m.user_name }
}
output "s3_iam_access_keys" {
  description = "Map of IAM access key IDs for each user"
  value       = { for k, m in module.s3_users : k => m.access_key_id }
  sensitive   = true
}
output "s3_iam_secret_keys" {
  description = "Map of IAM secret access keys for each user"
  value       = { for k, m in module.s3_users : k => m.secret_access_key }
  sensitive   = true
}
# S3 end


# openproject start
output "s3_bucket_name" {
  description = "Name of the S3 bucket for OpenProject attachments"
  value       = module.attachments_bucket.bucket_name
}
output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for OpenProject attachments"
  value       = module.attachments_bucket.bucket_arn
}
output "openproject_iam_user_name" {
  description = "IAM user created for OpenProject"
  value       = module.openproject_user.user_name
}
output "openproject_iam_access_key_id" {
  description = "Access key ID for the OpenProject IAM user (if created)"
  value       = module.openproject_user.access_key_id
  sensitive   = true
}
output "openproject_iam_secret_access_key" {
  description = "Secret access key for the OpenProject IAM user (if created)"
  value       = module.openproject_user.secret_access_key
  sensitive   = true
}
# openproject end

# ECR start
output "ecr_repositories" {
  description = "Repository URLs for all created ECRs"
  value = {
    for name, repo in module.ecr :
    name => repo.repository_url
  }
}
output "ecr_iam_user_name" {
  description = "entire ecr access user"
  value       = module.ecr_users.user_name
}
output "ecr_iam_access_key" {
  description = "entire ecr access user"
  value       = module.ecr_users.access_key_id
  sensitive   = true
}
output "ecr_iam_secret_key" {
  description = "entire ecr access user"
  value       = module.ecr_users.secret_access_key
  sensitive   = true
}
# ECR end

output "dev_no_reply_ses_user_name" {
  description = "IAM username for the SES user"
  value       = module.dev_ses_user.user_name
}

output "dev_no_reply_ses_user_access_key_id" {
  description = "Access key ID for the SES user (if created)"
  value       = try(module.dev_ses_user.access_key_id, null)
  sensitive   = true
}

output "dev_no_reply_ses_user_secret_access_key" {
  description = "Secret access key for the SES user (if created)"
  value       = try(module.dev_ses_user.secret_access_key, null)
  sensitive   = true
}
