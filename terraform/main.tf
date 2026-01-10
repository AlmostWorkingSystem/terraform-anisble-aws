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

resource "aws_key_pair" "tf_key" {
  key_name   = "tf_key"
  public_key = file("../keys/tf_key.pub")
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
    # # OPEN-PROJECT INSTANCE
    # openproject = {
    #   instance_type = "t4g.medium"
    #   key_name      = aws_key_pair.tf_key.key_name
    #   sg_ids        = [for sg in module.security_group : sg]
    #   volume_size   = 20
    #   assign_eip    = true
    #   ami_id        = var.ami_id_deb
    #   ami_id        = "ami-08a74fd5a291db25a"
    # }
    # db = {
    #   instance_type = "c6g.medium"
    #   ami_id        = "ami-0a09e1f2ce12e0af6"
    #   key_name      = aws_key_pair.tf_key.key_name
    #   sg_ids        = [for sg in module.security_group : sg]
    #   volume_size   = 30
    #   assign_eip    = true
    # },
    # coolify = {
    #   instance_type = "c6g.large"
    #   ami_id        = "ami-0a09e1f2ce12e0af6"
    #   key_name      = aws_key_pair.tf_key.key_name
    #   sg_ids        = [for sg in module.security_group : sg]
    #   volume_size   = 30
    #   assign_eip    = true
    # }
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

# resource "aws_route53_record" "hub_erp" {
#   zone_id = var.kiet_domain_zone_id
#   name    = "hub.erp"
#   type    = "A"
#   ttl     = 300
#   records = [module.aws_instance["openproject"].public_ip]
# }

locals {
  s3_buckets = {
    "meritto-integration-kiet" = {
      force_destroy       = false
      block_public_policy = true
    },
    "learning-s3-storage" = {
      force_destroy       = true
      block_public_policy = true
    },
    "erp3-attachments" = {
      force_destroy       = true
      block_public_policy = false
    },
    "postgres-all-db-backup" = {
      force_destroy       = true
      block_public_policy = true
    }
  }
}

module "s3_buckets" {
  for_each = local.s3_buckets
  source   = "./modules/s3"

  bucket_name         = each.key
  force_destroy       = each.value.force_destroy
  block_public_policy = each.value.block_public_policy
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
}

# CloudFront distribution for erp3-attachments bucket
module "erp3_attachments_cloudfront" {
  source = "./modules/cloudfront"

  bucket_name                 = "erp3-attachments"
  bucket_regional_domain_name = module.s3_buckets["erp3-attachments"].bucket_regional_domain_name
  bucket_arn                  = module.s3_buckets["erp3-attachments"].bucket_arn

  distribution_comment = "CloudFront CDN for ERP3 attachments (images)"

  # Cache settings optimized for images
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  # Enable compression for better performance
  compress = true

  # Redirect HTTP to HTTPS
  viewer_protocol_policy = "redirect-to-https"

  # Use cost-effective price class (North America and Europe)
  price_class = "PriceClass_200"

  tags = {
    Name        = "erp3-attachments-cdn"
    Environment = "production"
    Purpose     = "Image caching for ERP3"
  }
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

  inline_policies = {
    "SES_SendEmail" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        # Restrict sending actions to a specific from-address
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
              "ses:FromAddress" = "dev-no-reply@kiet.co.in"
            }
          }
        },
        # Allow quota/statistics actions without restriction
        {
          Sid    = "AllowViewSESQuotaAndStats"
          Effect = "Allow"
          Action = [
            "ses:GetSendQuota",
            "ses:GetSendStatistics"
          ]
          Resource = "*"
        }
      ]
    })
  }
}


#################################### ses end ####################################
