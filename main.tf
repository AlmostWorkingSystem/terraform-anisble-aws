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

resource "aws_key_pair" "tf_key" {
  key_name   = "my-ssh-key"
  public_key = file("keys/tf_key.pub")
}

locals {
  ec2 = {
    tf_demo_erp = {
      instance_type = "t3.micro"
      key_name      = aws_key_pair.tf_key.key_name
      sg_ids        = [for sg in module.security_group : sg]
      subdomain     = "dev.erp"
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
  assign_eip    = each.value.assign_eip
}

resource "aws_route53_record" "subdomain" {
  zone_id = var.kiet_domain_zone_id
  name    = local.ec2.tf_demo_erp.subdomain
  type    = "A"
  ttl     = 10
  records = [module.aws_instance["tf_demo_erp"].public_ip]
}
