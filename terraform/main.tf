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
        "172.31.21.201/32",
        "172.31.25.87/32",

        "173.245.48.0/20",
        "103.21.244.0/22",
        "103.22.200.0/22",
        "103.31.4.0/22",
        "141.101.64.0/18",
        "108.162.192.0/18",
        "190.93.240.0/20",
        "188.114.96.0/20",
        "197.234.240.0/22",
        "198.41.128.0/17",
        "162.158.0.0/15",
        "104.16.0.0/13",
        "104.24.0.0/14",
        "172.64.0.0/13",
        "131.0.72.0/22",

        # ! Remove this
        "0.0.0.0/0"
      ]
      ipv6_cidr_blocks = [
        "2400:cb00::/32",
        "2606:4700::/32",
        "2803:f800::/32",
        "2405:b500::/32",
        "2405:8100::/32",
        "2a06:98c0::/29",
        "2c0f:f248::/32"
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
    db = {
      instance_type = "t4g.small"
      key_name      = aws_key_pair.tf_key.key_name
      sg_ids        = [for sg in module.sg_db : sg]
      volume_size   = 20
      assign_eip    = true
      ami_id        = "ami-08a74fd5a291db25a"
    },
    # OPEN-PROJECT INSTANCE
    openproject = {
      instance_type = "t4g.medium"
      key_name      = aws_key_pair.tf_key.key_name
      sg_ids        = [for sg in module.security_group : sg]
      volume_size   = 20
      assign_eip    = true
      ami_id        = var.ami_id_deb
      ami_id        = "ami-08a74fd5a291db25a"
    }
    staging = {
      instance_type = "t4g.large"
      ami_id        = "ami-08a74fd5a291db25a"
      key_name      = aws_key_pair.tf_key.key_name
      sg_ids        = [for sg in module.security_group : sg]
      volume_size   = 25
      assign_eip    = true
    }
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
        {
          Effect = "Allow"
          Action = [
            "ses:SendEmail",
            "ses:SendRawEmail"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

#################################### ses end ####################################
