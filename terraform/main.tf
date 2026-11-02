data "aws_vpc" "default" {
  default = true
}

module "security_group" {
  name   = "sg_ec2"
  source = "./modules/security-group"
  vpc_id = data.aws_vpc.default.id

  ingress_rules = [
    {
      description = "Allow HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    # {
    #   description = "Allow HTTP"
    #   from_port   = 8000
    #   to_port     = 8000
    #   protocol    = "tcp"
    #   cidr_blocks = ["0.0.0.0/0"]
    # },
    {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [{
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}


module "sg_db" {
  name   = "sg_db"
  source = "./modules/security-group"
  vpc_id = data.aws_vpc.default.id

  ingress_rules = [
    {
      description = "Allow SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "PG Bouncer"
      from_port   = 6432
      to_port     = 6432
      protocol    = "tcp"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
      ipv6_cidr_blocks = [
      ]
    },
    {
      description = "Redis port"
      from_port   = 1112
      to_port     = 1112
      protocol    = "tcp"
      cidr_blocks = ["172.31.21.201/32", "172.31.25.87/32"]
    }
  ]
  egress_rules = [{
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]

}

locals {
  # Public half of the admins' SSH key (same key in every region)
  tf_key_public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhbljfux51iag9402Ib3CrYDBfAjPWJmpXq1VEUq43b pranjal@PRANJALs-MacBook-Air.local"
}

resource "aws_key_pair" "tf_key" {
  key_name   = "tf_key"
  public_key = local.tf_key_public
}

# sg_ids        = [for sg in module.security_group : sg]
locals {
  ec2 = {
    # db = {
    #   instance_type = "t4g.small"
    #   key_name      = aws_key_pair.tf_key.key_name
    #   sg_ids        = [for sg in module.sg_db : sg]
    #   volume_size   = 20
    #   assign_eip    = true
    #   ami_id        = "ami-08a74fd5a291db25a"
    # },
  }
}

module "aws_instance" {
  source = "./modules/ec2"

  for_each = local.ec2

  instance_name     = each.key
  ami_id            = each.value.ami_id
  instance_type     = each.value.instance_type
  key_name          = each.value.key_name
  sg_ids            = each.value.sg_ids
  assign_eip        = lookup(each.value, "assign_eip", false)
  volume_size       = each.value.volume_size
  availability_zone = "ap-south-2c"
}

locals {
  s3_buckets = {
    "meritto-integration-kiet" = {
      force_destroy       = false
      block_public_policy = true
    },
    "erp3-attachments" = {
      user_tags           = { AKIAQN6AAPCNBREDA2PY = "staging development" }
      force_destroy       = true
      block_public_policy = true
      fully_private       = true
    },
    "kiet-erp3-attachments-prod" = {
      force_destroy       = false
      block_public_policy = true
      fully_private       = true
    }
  }
}

module "s3_buckets" {
  for_each = local.s3_buckets
  source   = "./modules/s3"

  bucket_name             = each.key
  force_destroy           = each.value.force_destroy
  block_public_policy     = each.value.block_public_policy
  ignore_public_acls      = lookup(each.value, "fully_private", false)
  restrict_public_buckets = lookup(each.value, "fully_private", false)
}

# Create IAM policies for each bucket dynamically
resource "aws_iam_policy" "s3_bucket_policy" {
  for_each = local.s3_buckets

  name        = "${each.key}-policy"
  description = "Access to ${each.key} bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          module.s3_buckets[each.key].bucket_arn,
          "${module.s3_buckets[each.key].bucket_arn}/*"
        ]
      }
    ]
  })
}

# Create IAM users dynamically
module "s3_users" {
  for_each = local.s3_buckets
  source   = "./modules/iam"

  user_name           = "s3-${each.key}-user"
  managed_policy_arns = [aws_iam_policy.s3_bucket_policy[each.key].arn]
  tags                = lookup(each.value, "user_tags", {})
}

########################### op-attachments ####################################
module "attachments_bucket" {
  source                   = "./modules/s3"
  bucket_name              = "op-attachments"
  force_destroy            = true
  aws_s3_bucket_versioning = "Disabled"
}

resource "aws_iam_policy" "openproject_bucket_policy" {
  name        = "OpenProjectS3Access"
  description = "Access to OpenProject attachments bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.attachments_bucket.bucket_arn,
          "${module.attachments_bucket.bucket_arn}/*"
        ]
      }
    ]
  })
}

module "openproject_user" {
  source              = "./modules/iam"
  user_name           = "openproject-s3-user"
  managed_policy_arns = [aws_iam_policy.openproject_bucket_policy.arn]
}
########################### op-attachments ####################################



#################################### ecr start ####################################
locals {
  ecr = {
    "erp_frontend" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = false
      # tags = {
      #   Environment = "dev"
      #   Project     = "my-project"
      # }
    }
    "erp_backend" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      # tags = {
      #   Environment = "staging"
      #   Project     = "another-project"
      # }
    }
  }
}

module "ecr" {
  source   = "./modules/ecr"
  for_each = local.ecr

  repository_name      = each.key
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push
  tags                 = can(each.value.tags) ? each.value.tags : null
}

data "aws_iam_policy_document" "ecr_access" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage"
    ]
    resources = [
      for repo in module.ecr : repo.repository_arn
    ]
  }

  # Needed so the user can authenticate
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

module "ecr_users" {
  source = "./modules/iam"

  user_name           = "ecr-admin-user"
  managed_policy_arns = []

  inline_policies = {
    ecr_custom = data.aws_iam_policy_document.ecr_access.json
  }
}
#################################### ecr end ####################################

#################################### ses start ####################################

module "ses_user" {
  source            = "./modules/iam"
  user_name         = "ses-django-user"
  create_access_key = true

  inline_policies = {
    "SES_SendEmail" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        # Restrict email sending to a specific from-address
        {
          Sid    = "AllowSendEmailFromSpecificAddress"
          Effect = "Allow"
          Action = [
            "ses:SendEmail",
            "ses:SendRawEmail"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "ses:FromAddress" = "no-reply@kiet.co.in"
            }
          }
        },
        # Allow viewing SES quota and send statistics
        {
          Sid    = "AllowSESQuotaAndStats"
          Effect = "Allow"
          Action = [
            "ses:GetSendQuota",
            "ses:GetSendStatistics"
          ]
          Resource = "*"
        },
        # Allow managing email templates
        {
          Sid    = "AllowManageEmailTemplates"
          Effect = "Allow"
          Action = [
            "ses:CreateTemplate",
            "ses:GetTemplate",
            "ses:UpdateTemplate",
            "ses:DeleteTemplate",
            "ses:ListTemplates",
            "ses:TestRenderTemplate"
          ]
          Resource = "*"
        },
        # Allow domain verification and identity management
        {
          Sid    = "AllowDomainVerification"
          Effect = "Allow"
          Action = [
            "ses:VerifyDomainDkim",
            "ses:VerifyDomainIdentity",
            "ses:GetIdentityVerificationAttributes",
            "ses:GetIdentityDkimAttributes",
            "ses:SetIdentityDkimEnabled",
            "ses:SetIdentityMailFromDomain",
            "ses:GetIdentityMailFromDomainAttributes",
            "ses:SetIdentityNotificationTopic",
            "ses:GetIdentityNotificationAttributes",
            "ses:SetIdentityFeedbackForwardingEnabled",
            "ses:SetIdentityHeadersInNotificationsEnabled"
          ]
          Resource = "*"
        }
      ]
    })
  }
}


module "dev_ses_user" {
  source            = "./modules/iam"
  user_name         = "dev-ses-django-user"
  create_access_key = true
  tags              = { AKIAQN6AAPCNOQIFRRQQ = "development staging" }

  inline_policies = {
    "SES_SendEmail" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowSendFromAllVerifiedSESIdentities"
          Effect    = "Allow"
          Action    = ["ses:SendEmail", "ses:SendRawEmail"]
          Resource  = "arn:aws:ses:ap-south-1:${data.aws_caller_identity.current.account_id}:identity/*"
          Condition = { StringEquals = { "aws:RequestedRegion" = "ap-south-1" } }
        },
        {
          Sid       = "AllowUseConfigurationSet"
          Effect    = "Allow"
          Action    = ["ses:SendEmail", "ses:SendRawEmail"]
          Resource  = "arn:aws:ses:ap-south-1:${data.aws_caller_identity.current.account_id}:configuration-set/my-configuration-set-name"
          Condition = { StringEquals = { "aws:RequestedRegion" = "ap-south-1" } }
        },
        {
          Sid       = "AllowGetSendQuotaAndStats"
          Effect    = "Allow"
          Action    = ["ses:GetSendQuota", "ses:GetSendStatistics"]
          Resource  = "*"
          Condition = { StringEquals = { "aws:RequestedRegion" = "ap-south-1" } }
        },
        {
          Sid       = "AllowManageTemplates"
          Effect    = "Allow"
          Action    = ["ses:CreateTemplate", "ses:GetTemplate", "ses:UpdateTemplate", "ses:DeleteTemplate", "ses:ListTemplates", "ses:TestRenderTemplate"]
          Resource  = "*"
          Condition = { StringEquals = { "aws:RequestedRegion" = "ap-south-1" } }
        },
      ]
    })
  }
}


#################################### ses end ####################################

#################################### other buckets start ####################################
# Buckets without the per-bucket "s3-<name>-user" pattern above
locals {
  other_buckets = {
    # WhatsApp media, public read (used by social-messaging-user)
    "wa-kiet-media" = {
      region              = "ap-south-2"
      block_public_policy = false
    }
    # Email images (img/* is public), sent and received attachments
    "kiet-erp3-email-dev" = {
      region              = "ap-south-1"
      block_public_policy = false
      block_public_acls   = true
      ignore_public_acls  = true
    }
    # SES inbound mail drop
    "kiet-erp3-email-inbound-dev" = {
      region                  = "ap-south-1"
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
  }
}

module "other_buckets" {
  for_each = local.other_buckets
  source   = "./modules/s3"

  bucket_name             = each.key
  region                  = each.value.region
  block_public_policy     = lookup(each.value, "block_public_policy", true)
  block_public_acls       = lookup(each.value, "block_public_acls", null)
  ignore_public_acls      = lookup(each.value, "ignore_public_acls", false)
  restrict_public_buckets = lookup(each.value, "restrict_public_buckets", false)
}

resource "aws_s3_bucket_policy" "wa_kiet_media" {
  bucket = module.other_buckets["wa-kiet-media"].bucket_name
  region = "ap-south-2"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${module.other_buckets["wa-kiet-media"].bucket_arn}/*"
    }]
  })
}

# Note: erp3-email-dev may rewrite this policy itself (it has s3:PutBucketPolicy)
resource "aws_s3_bucket_policy" "email_dev" {
  bucket = module.other_buckets["kiet-erp3-email-dev"].bucket_name
  region = "ap-south-1"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadsEmailImages"
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = "s3:GetObject"
      Resource  = "${module.other_buckets["kiet-erp3-email-dev"].bucket_arn}/img/*"
    }]
  })
}

resource "aws_s3_bucket_policy" "email_inbound_dev" {
  bucket = module.other_buckets["kiet-erp3-email-inbound-dev"].bucket_name
  region = "ap-south-1"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "SesStoresReceivedMail"
      Effect    = "Allow"
      Principal = { Service = "ses.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${module.other_buckets["kiet-erp3-email-inbound-dev"].bucket_arn}/*"
      Condition = { StringEquals = { "AWS:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}
#################################### other buckets end ####################################

#################################### other iam users start ####################################
module "social_messaging_user" {
  source              = "./modules/iam"
  user_name           = "social-messaging-user"
  managed_policy_arns = [aws_iam_policy.wa_kiet_media.arn]

  inline_policies = {
    SocialMessagingAccess = jsonencode({
      Version   = "2012-10-17"
      Statement = [{ Effect = "Allow", Action = "social-messaging:*", Resource = "*" }]
    })
  }
}

resource "aws_iam_policy" "wa_kiet_media" {
  name        = "s3-wa-kiet-media"
  description = "for WHATSAPP_MEDIA_S3_BUCKET on social-messaging-user"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:*", "s3-object-lambda:*"]
      Resource = [module.other_buckets["wa-kiet-media"].bucket_arn, "${module.other_buckets["wa-kiet-media"].bucket_arn}/*"]
    }]
  })
}

module "cloudfront_admin" {
  source              = "./modules/iam"
  user_name           = "cloudfront_admin"
  managed_policy_arns = ["arn:aws:iam::aws:policy/CloudFrontFullAccess"]
}

# Copies prod attachments into the staging bucket (migration server)
module "attachments_migration_user" {
  source              = "./modules/iam"
  user_name           = "read_kiet-erp3-attachments-prod_write_erp3-attachments"
  managed_policy_arns = [aws_iam_policy.attachments_migration.arn]
  tags                = { AKIAQN6AAPCNOQOW7PV4 = "for migration_server" }
}

resource "aws_iam_policy" "attachments_migration" {
  name = "read_kiet-erp3-attachments-prod_write_erp3-attachments"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Sid = "ReadFromProdBucket", Effect = "Allow", Action = ["s3:ListBucket"], Resource = module.s3_buckets["kiet-erp3-attachments-prod"].bucket_arn },
      { Sid = "ReadObjectsFromProdBucket", Effect = "Allow", Action = ["s3:GetObject"], Resource = "${module.s3_buckets["kiet-erp3-attachments-prod"].bucket_arn}/*" },
      { Sid = "WriteToStagingBucket", Effect = "Allow", Action = ["s3:ListBucket"], Resource = module.s3_buckets["erp3-attachments"].bucket_arn },
      { Sid = "WriteObjectsToStagingBucket", Effect = "Allow", Action = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"], Resource = "${module.s3_buckets["erp3-attachments"].bucket_arn}/*" },
    ]
  })
}

module "admissions_ses_user" {
  source              = "./modules/iam"
  user_name           = "admissions@kiet.co.in"
  managed_policy_arns = [aws_iam_policy.admissions_ses.arn]
}

resource "aws_iam_policy" "admissions_ses" {
  name = "admission@kiet.co.in"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSendOnlyFromAdmissionsEmail"
        Effect    = "Allow"
        Action    = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource  = "arn:aws:ses:ap-south-2:${data.aws_caller_identity.current.account_id}:identity/kiet.co.in"
        Condition = { StringEquals = { "aws:RequestedRegion" = "ap-south-2", "ses:FromAddress" = "admissions@kiet.co.in" } }
      },
      {
        Sid       = "AllowGetSendQuotaAndStats"
        Effect    = "Allow"
        Action    = ["ses:GetSendQuota", "ses:GetSendStatistics"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:RequestedRegion" = "ap-south-2" } }
      },
      {
        Sid       = "AllowManageTemplates"
        Effect    = "Allow"
        Action    = ["ses:CreateTemplate", "ses:GetTemplate", "ses:UpdateTemplate", "ses:DeleteTemplate", "ses:ListTemplates", "ses:TestRenderTemplate"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:RequestedRegion" = "ap-south-2" } }
      },
    ]
  })
}

# SES in ap-southeast-1 (mb.kiet.co.in)
module "mb_ses_user" {
  source              = "./modules/iam"
  user_name           = "mb-ses-admin"
  managed_policy_arns = [aws_iam_policy.mb_ses.arn]
}

resource "aws_iam_policy" "mb_ses" {
  name = "mb-ses-policy-testing"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = ["ses:CreateEmailIdentity", "ses:GetEmailIdentity", "ses:SendEmail"]
      Resource  = "*"
      Condition = { StringEquals = { "aws:RequestedRegion" = "ap-southeast-1" } }
    }]
  })
}

# EduVverse email (dev): SES send + email buckets
module "email_dev_user" {
  source    = "./modules/iam"
  user_name = "erp3-email-dev"
  tags      = { purpose = "eduvverse-email-dev" }

  inline_policies = {
    "erp3-email-dev" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        { Sid = "CheckAccountAndSenders", Effect = "Allow", Action = ["ses:GetAccount", "ses:ListEmailIdentities"], Resource = "*" },
        { Sid = "SendEmail", Effect = "Allow", Action = ["ses:SendEmail", "ses:SendRawEmail"], Resource = "*" },
        { Sid = "EmailImages", Effect = "Allow", Action = "s3:PutObject", Resource = "arn:aws:s3:::kiet-erp3-email-dev/img/*" },
        { Sid = "Attachments", Effect = "Allow", Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"], Resource = ["arn:aws:s3:::kiet-erp3-email-dev/sent/*", "arn:aws:s3:::kiet-erp3-email-dev/received/*"] },
        { Sid = "BucketPolicyButton", Effect = "Allow", Action = ["s3:PutBucketPolicy", "s3:PutBucketPublicAccessBlock"], Resource = "arn:aws:s3:::kiet-erp3-email-dev" },
        { Sid = "ReadReceivedMail", Effect = "Allow", Action = "s3:GetObject", Resource = "arn:aws:s3:::kiet-erp3-email-inbound-dev/*" },
      ]
    })
  }
}
#################################### other iam users end ####################################
