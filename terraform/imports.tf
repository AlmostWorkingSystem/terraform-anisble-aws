# Adopts resources that were created outside Terraform (synced 2 November 2026).
# Import blocks are no-ops once imported; delete this file after the first apply.

# CloudFront (hand-built in console)
import {
  to = aws_cloudfront_distribution.prod
  id = "E34Z198JLZGRUV"
}
import {
  to = aws_cloudfront_distribution.staging
  id = "E3DGPWQ0YF8I4A"
}
import {
  to = aws_cloudfront_origin_access_control.prod
  id = "E2CG0MF0PYDVEW"
}
import {
  to = aws_cloudfront_origin_access_control.staging
  id = "E36AHL8HJNNQDI"
}
import {
  to = aws_cloudfront_key_group.prod
  id = "94e65cb5-d755-4451-9d98-af7ef4eaf08b"
}
import {
  to = aws_cloudfront_key_group.staging
  id = "d4bc091a-329e-4f91-b524-0ecb0dfd7db1"
}
import {
  to = aws_cloudfront_public_key.prod
  id = "KC38BZ0UYUQYK"
}
import {
  to = aws_cloudfront_public_key.staging
  id = "KDRBSOXHDM6SS"
}
import {
  to = aws_s3_bucket_cors_configuration.attachments["kiet-erp3-attachments-prod"]
  id = "kiet-erp3-attachments-prod"
}
import {
  to = aws_s3_bucket_cors_configuration.attachments["erp3-attachments"]
  id = "erp3-attachments"
}
# Singapore staging_db
import {
  to = module.staging_db_sg.aws_security_group.this
  id = "sg-0a7dac65f34198127@ap-southeast-1"
}
import {
  to = module.aws_instance_ap_southeast_1["staging_db"].aws_instance.this
  id = "i-0ff84ad1a860cec4c@ap-southeast-1"
}
import {
  to = module.aws_instance_ap_southeast_1["staging_db"].aws_eip.this[0]
  id = "eipalloc-0e3894cf89046d150@ap-southeast-1"
}
import {
  to = module.aws_instance_ap_southeast_1["staging_db"].aws_eip_association.this[0]
  id = "eipassoc-06db3fcb5c88530a0@ap-southeast-1"
}
# Other buckets
import {
  to = module.other_buckets["wa-kiet-media"].aws_s3_bucket.this
  id = "wa-kiet-media"
}
import {
  to = module.other_buckets["wa-kiet-media"].aws_s3_bucket_public_access_block.this
  id = "wa-kiet-media"
}
import {
  to = module.other_buckets["kiet-erp3-email-dev"].aws_s3_bucket.this
  id = "kiet-erp3-email-dev@ap-south-1"
}
import {
  to = module.other_buckets["kiet-erp3-email-dev"].aws_s3_bucket_public_access_block.this
  id = "kiet-erp3-email-dev@ap-south-1"
}
import {
  to = module.other_buckets["kiet-erp3-email-inbound-dev"].aws_s3_bucket.this
  id = "kiet-erp3-email-inbound-dev@ap-south-1"
}
import {
  to = module.other_buckets["kiet-erp3-email-inbound-dev"].aws_s3_bucket_public_access_block.this
  id = "kiet-erp3-email-inbound-dev@ap-south-1"
}
import {
  to = aws_s3_bucket_policy.wa_kiet_media
  id = "wa-kiet-media"
}
import {
  to = aws_s3_bucket_policy.email_dev
  id = "kiet-erp3-email-dev@ap-south-1"
}
import {
  to = aws_s3_bucket_policy.email_inbound_dev
  id = "kiet-erp3-email-inbound-dev@ap-south-1"
}
# IAM
import {
  to = aws_iam_policy.wa_kiet_media
  id = "arn:aws:iam::029930584218:policy/s3-wa-kiet-media"
}
import {
  to = module.social_messaging_user.aws_iam_user_policy_attachment.managed["0"]
  id = "social-messaging-user/arn:aws:iam::029930584218:policy/s3-wa-kiet-media"
}
import {
  to = module.cloudfront_admin.aws_iam_user.this
  id = "cloudfront_admin"
}
import {
  to = module.cloudfront_admin.aws_iam_access_key.this[0]
  id = "AKIAQN6AAPCNKWEVZEJQ"
}
import {
  to = module.cloudfront_admin.aws_iam_user_policy_attachment.managed["0"]
  id = "cloudfront_admin/arn:aws:iam::aws:policy/CloudFrontFullAccess"
}
import {
  to = module.attachments_migration_user.aws_iam_user.this
  id = "read_kiet-erp3-attachments-prod_write_erp3-attachments"
}
import {
  to = module.attachments_migration_user.aws_iam_access_key.this[0]
  id = "AKIAQN6AAPCNOQOW7PV4"
}
import {
  to = module.attachments_migration_user.aws_iam_user_policy_attachment.managed["0"]
  id = "read_kiet-erp3-attachments-prod_write_erp3-attachments/arn:aws:iam::029930584218:policy/read_kiet-erp3-attachments-prod_write_erp3-attachments"
}
import {
  to = aws_iam_policy.attachments_migration
  id = "arn:aws:iam::029930584218:policy/read_kiet-erp3-attachments-prod_write_erp3-attachments"
}
import {
  to = module.admissions_ses_user.aws_iam_user.this
  id = "admissions@kiet.co.in"
}
import {
  to = module.admissions_ses_user.aws_iam_access_key.this[0]
  id = "AKIAQN6AAPCNNH63RL7V"
}
import {
  to = module.admissions_ses_user.aws_iam_user_policy_attachment.managed["0"]
  id = "admissions@kiet.co.in/arn:aws:iam::029930584218:policy/admission@kiet.co.in"
}
import {
  to = aws_iam_policy.admissions_ses
  id = "arn:aws:iam::029930584218:policy/admission@kiet.co.in"
}
import {
  to = module.mb_ses_user.aws_iam_user.this
  id = "mb-ses-admin"
}
import {
  to = module.mb_ses_user.aws_iam_access_key.this[0]
  id = "AKIAQN6AAPCNGBDEGYXQ"
}
import {
  to = module.mb_ses_user.aws_iam_user_policy_attachment.managed["0"]
  id = "mb-ses-admin/arn:aws:iam::029930584218:policy/mb-ses-policy-testing"
}
import {
  to = aws_iam_policy.mb_ses
  id = "arn:aws:iam::029930584218:policy/mb-ses-policy-testing"
}
import {
  to = module.email_dev_user.aws_iam_user.this
  id = "erp3-email-dev"
}
import {
  to = module.email_dev_user.aws_iam_access_key.this[0]
  id = "AKIAQN6AAPCNCNWQ7WJC"
}
import {
  to = module.email_dev_user.aws_iam_user_policy.inline["erp3-email-dev"]
  id = "erp3-email-dev:erp3-email-dev"
}

# Access keys rotated by hand on 26 May 2026. The old key ids are still in state, so
# these imports only take effect after `terraform apply -refresh-only` drops them (see README).
import {
  to = module.dev_ses_user.aws_iam_access_key.this[0]
  id = "AKIAQN6AAPCNFI4IHQGS"
}
import {
  to = module.rekognition_user.aws_iam_access_key.this[0]
  id = "AKIAQN6AAPCNKEPANHMV"
}
import {
  to = module.s3_users["erp3-attachments"].aws_iam_access_key.this[0]
  id = "AKIAQN6AAPCNFQTORFRR"
}
