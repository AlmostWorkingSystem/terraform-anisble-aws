#################################### email (kiet.eduvverse.com) start ####################################
# EduVverse email account for KIET: sending and receiving on kiet.eduvverse.com, SES in ap-south-1.
# Permissions follow the backend's docs/design/aws-permissions.html ("AWS permissions for
# EduVverse communication", 2 November 2026). No CloudFront: pictures load from the bucket's
# public img/ folder; attachments (sent/, received/) open through S3 presigned links.
#
# Values for the email account form in EduVverse: `terraform output email_account`.
# DNS (DKIM, MX) lives in ../cloudflare/eduvverse.tf.

locals {
  email_region         = "ap-south-1"
  email_domain         = "kiet.eduvverse.com"
  email_bucket         = "kiet-eduvverse-email"
  email_inbound_bucket = "kiet-eduvverse-email-inbound"
  # Only one receipt rule set can be active per region; it already holds the dev rule.
  ses_active_rule_set = "erp3-email-dev"
}

variable "email_webhook_url" {
  description = "Backend webhook for SNS, e.g. https://<backend>/v1/communication_email/webhook/. Leave empty until the latest backend is live; it confirms the subscriptions itself."
  type        = string
  default     = ""
}

# --- Buckets ---------------------------------------------------------------

# img/ is public (pictures inside emails); sent/ and received/ stay private.
module "email_bucket" {
  source                  = "./modules/s3"
  bucket_name             = local.email_bucket
  region                  = local.email_region
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# Same policy and public access block the account's "Update bucket policy" button writes
# (without CloudFront), so pressing it causes no drift.
resource "aws_s3_bucket_policy" "email_bucket" {
  bucket = module.email_bucket.bucket_name
  region = local.email_region
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadsEmailImages"
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = "s3:GetObject"
      Resource  = "${module.email_bucket.bucket_arn}/img/*"
    }]
  })

  # A new bucket blocks public policies until the module's public access block is applied
  depends_on = [module.email_bucket]
}

# Raw received mail, written by SES. Fully private.
module "email_inbound_bucket" {
  source                  = "./modules/s3"
  bucket_name             = local.email_inbound_bucket
  region                  = local.email_region
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "email_inbound_bucket" {
  bucket = module.email_inbound_bucket.bucket_name
  region = local.email_region
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "SesStoresReceivedMail"
      Effect    = "Allow"
      Principal = { Service = "ses.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${module.email_inbound_bucket.bucket_arn}/*"
      Condition = { StringEquals = { "AWS:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}

# --- SES -------------------------------------------------------------------

resource "aws_sesv2_email_identity" "kiet_eduvverse" {
  region         = local.email_region
  email_identity = local.email_domain
}

resource "aws_sesv2_configuration_set" "kiet_eduvverse" {
  region                 = local.email_region
  configuration_set_name = "kiet-eduvverse-email"

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }
}

resource "aws_sesv2_configuration_set_event_destination" "kiet_eduvverse" {
  region                 = local.email_region
  configuration_set_name = aws_sesv2_configuration_set.kiet_eduvverse.configuration_set_name
  event_destination_name = "to-sns"

  event_destination {
    enabled              = true
    matching_event_types = ["SEND", "DELIVERY", "DELIVERY_DELAY", "BOUNCE", "COMPLAINT", "REJECT", "RENDERING_FAILURE", "OPEN", "CLICK", "SUBSCRIPTION"]

    sns_destination {
      topic_arn = aws_sns_topic.email["events"].arn
    }
  }
}

resource "aws_ses_receipt_rule" "kiet_eduvverse" {
  region        = local.email_region
  name          = "kiet-eduvverse-to-s3"
  rule_set_name = local.ses_active_rule_set
  recipients    = [local.email_domain]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Optional"

  s3_action {
    position    = 1
    bucket_name = module.email_inbound_bucket.bucket_name
    topic_arn   = aws_sns_topic.email["inbound"].arn
  }

  # SES checks it may write to the bucket and publish to the topic when the rule is saved
  depends_on = [aws_s3_bucket_policy.email_inbound_bucket, aws_sns_topic_policy.email]
}

# --- SNS -------------------------------------------------------------------
# events: delivery, bounce, open, click... from the configuration set
# inbound: "a new email arrived" from the receipt rule

resource "aws_sns_topic" "email" {
  for_each = toset(["events", "inbound"])
  region   = local.email_region
  name     = "kiet-eduvverse-email-${each.key}"
}

resource "aws_sns_topic_policy" "email" {
  for_each = aws_sns_topic.email
  region   = local.email_region
  arn      = each.value.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "OwnerManages"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = ["SNS:GetTopicAttributes", "SNS:SetTopicAttributes", "SNS:AddPermission", "SNS:RemovePermission", "SNS:DeleteTopic", "SNS:Subscribe", "SNS:ListSubscriptionsByTopic", "SNS:Publish"]
        Resource  = each.value.arn
        Condition = { StringEquals = { "AWS:SourceOwner" = data.aws_caller_identity.current.account_id } }
      },
      {
        Sid       = "SesPublishes"
        Effect    = "Allow"
        Principal = { Service = "ses.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = each.value.arn
        Condition = { StringEquals = { "AWS:SourceAccount" = data.aws_caller_identity.current.account_id } }
      },
    ]
  })
}

resource "aws_sns_topic_subscription" "email_webhook" {
  for_each               = var.email_webhook_url == "" ? {} : aws_sns_topic.email
  region                 = local.email_region
  topic_arn              = each.value.arn
  protocol               = "https"
  endpoint               = var.email_webhook_url
  endpoint_auto_confirms = true
}

# --- The email account's AWS key ---------------------------------------------
# Sending limited to kiet.eduvverse.com and its configuration set.

module "kiet_eduvverse_email_user" {
  source    = "./modules/iam"
  user_name = "kiet-eduvverse-email"
  tags      = { purpose = "eduvverse-email-kiet" }

  inline_policies = {
    "eduvverse-email" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "CheckAccountAndSenders"
          Effect   = "Allow"
          Action   = ["ses:GetAccount", "ses:ListEmailIdentities"]
          Resource = "*"
        },
        {
          Sid      = "SendEmail"
          Effect   = "Allow"
          Action   = ["ses:SendEmail", "ses:SendRawEmail"]
          Resource = [aws_sesv2_email_identity.kiet_eduvverse.arn, aws_sesv2_configuration_set.kiet_eduvverse.arn]
        },
        {
          Sid      = "EmailImages"
          Effect   = "Allow"
          Action   = "s3:PutObject"
          Resource = "${module.email_bucket.bucket_arn}/img/*"
        },
        {
          Sid      = "Attachments"
          Effect   = "Allow"
          Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
          Resource = ["${module.email_bucket.bucket_arn}/sent/*", "${module.email_bucket.bucket_arn}/received/*"]
        },
        {
          Sid      = "BucketPolicyButton"
          Effect   = "Allow"
          Action   = ["s3:PutBucketPolicy", "s3:PutBucketPublicAccessBlock"]
          Resource = module.email_bucket.bucket_arn
        },
        {
          Sid      = "ReadReceivedMail"
          Effect   = "Allow"
          Action   = "s3:GetObject"
          Resource = "${module.email_inbound_bucket.bucket_arn}/*"
        },
      ]
    })
  }
}

output "email_account" {
  description = "Values for Communication > Email > Accounts in EduVverse (the secret: terraform output -raw email_account_secret_key)"
  value = {
    aws_region            = local.email_region
    aws_access_key_id     = nonsensitive(module.kiet_eduvverse_email_user.access_key_id) # key id is not secret
    configuration_set     = aws_sesv2_configuration_set.kiet_eduvverse.configuration_set_name
    sns_topic_arn         = aws_sns_topic.email["events"].arn
    bucket                = module.email_bucket.bucket_name
    inbound_region        = local.email_region
    inbound_domain        = local.email_domain
    inbound_bucket        = module.email_inbound_bucket.bucket_name
    inbound_sns_topic_arn = aws_sns_topic.email["inbound"].arn
  }
}

output "email_account_secret_key" {
  value     = module.kiet_eduvverse_email_user.secret_access_key
  sensitive = true
}

output "email_dns_records" {
  description = "DNS records for kiet.eduvverse.com (managed in ../cloudflare/eduvverse.tf)"
  value = {
    dkim = [for t in aws_sesv2_email_identity.kiet_eduvverse.dkim_signing_attributes[0].tokens : { name = "${t}._domainkey.${local.email_domain}", type = "CNAME", content = "${t}.dkim.amazonses.com" }]
    mx   = { name = local.email_domain, type = "MX", priority = 10, content = "inbound-smtp.${local.email_region}.amazonaws.com" }
  }
}
#################################### email (kiet.eduvverse.com) end ####################################
