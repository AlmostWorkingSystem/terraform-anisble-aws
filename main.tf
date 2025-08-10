data "aws_vpc" "default" {
  default = true
}

module "security_group" {
  source       = "./modules/security-group"
  vpc_id       = data.aws_vpc.default.id
}