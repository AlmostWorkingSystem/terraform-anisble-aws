#################################### ap-southeast-1 (Singapore) start ####################################
# Synced from live AWS on 2 November 2026.

data "aws_vpc" "default_ap_southeast_1" {
  provider = aws.ap_southeast_1
  default  = true
}

resource "aws_key_pair" "tf_key_ap_southeast_1" {
  provider   = aws.ap_southeast_1
  key_name   = "tf_key"
  public_key = local.tf_key_public
}

# Used by prod_backend. Despite the name it also opens Postgres to the internet.
module "security_group_ssh_only_ap_southeast_1" {
  source    = "./modules/security-group"
  providers = { aws = aws.ap_southeast_1 }
  name      = "sg_ssh_only_ap_southeast_1"
  vpc_id    = data.aws_vpc.default_ap_southeast_1.id

  ingress_rules = [
    {
      description = "Allow SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow Postgres"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

  egress_rules = [{
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

module "staging_db_sg" {
  source      = "./modules/security-group"
  providers   = { aws = aws.ap_southeast_1 }
  name        = "staging_db_sg"
  description = "allow ssh & db port access "
  vpc_id      = data.aws_vpc.default_ap_southeast_1.id

  ingress_rules = [
    {
      description = ""
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = ""
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

  egress_rules = [{
    description = ""
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

locals {
  ec2_ap_southeast_1 = {
    # Stopped when checked on 2 November 2026
    prod_backend = {
      instance_type = "t4g.medium"
      sg_ids        = [module.security_group_ssh_only_ap_southeast_1.id]
      volume_size   = 25
    }
    staging_db = {
      instance_type = "t4g.small"
      sg_ids        = [module.staging_db_sg.id]
      volume_size   = 41
      volume_tags   = { Name = "staging_db" }
    }
  }
}

module "aws_instance_ap_southeast_1" {
  source    = "./modules/ec2"
  providers = { aws = aws.ap_southeast_1 }
  for_each  = local.ec2_ap_southeast_1

  instance_name     = each.key
  ami_id            = "ami-098d7f3f866fca1fd" # debian-13-arm64-20251006-2257
  instance_type     = each.value.instance_type
  key_name          = aws_key_pair.tf_key_ap_southeast_1.key_name
  sg_ids            = each.value.sg_ids
  assign_eip        = true
  volume_size       = each.value.volume_size
  root_volume_tags  = lookup(each.value, "volume_tags", {})
  availability_zone = "ap-southeast-1a"
}
#################################### ap-southeast-1 (Singapore) end ####################################
