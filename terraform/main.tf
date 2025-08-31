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
      description = "Postgres port"
      from_port   = 1111
      to_port     = 1111
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

resource "aws_key_pair" "tf_key" {
  key_name   = "tf_key"
  public_key = file("../keys/tf_key.pub")
}

# sg_ids        = [for sg in module.security_group : sg]
locals {
  ec2 = {
    staging_db = {
      instance_type = "t3.small"
      key_name      = aws_key_pair.tf_key.key_name
      sg_ids        = [for sg in module.sg_db : sg]
      volume_size   = 20
      assign_eip    = true
    },
    staging = {
      instance_type = "t3.medium"
      key_name      = aws_key_pair.tf_key.key_name
      sg_ids        = [for sg in module.security_group : sg]
      volume_size   = 50
      assign_eip    = true

    }
  }
}

module "aws_instance" {
  source = "./modules/ec2"

  for_each = local.ec2

  instance_name = each.key
  ami_id        = var.ami_id_deb
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  sg_ids        = each.value.sg_ids
  assign_eip    = lookup(each.value, "assign_eip", false)
  volume_size   = each.value.volume_size
}

resource "aws_route53_record" "dev_erp" {
  zone_id = var.kiet_domain_zone_id
  name    = "erp"
  type    = "A"
  ttl     = 300
  records = [module.aws_instance["staging"].public_ip]
}

resource "aws_route53_record" "_dev_erp" {
  zone_id = var.kiet_domain_zone_id
  name    = "*.erp"
  type    = "A"
  ttl     = 300
  records = [module.aws_instance["staging"].public_ip]
}

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
  source = "./modules/iam"

  user_name = "openproject-s3-user"

  managed_policy_arns = [aws_iam_policy.openproject_bucket_policy.arn]
}
