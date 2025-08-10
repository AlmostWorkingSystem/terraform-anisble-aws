resource "aws_security_group" "ssh_access" {
  name        = "ssh-access"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "http_access" {
  name = "Allow http traffic"
  description = "Allow all http traffic for everywhere"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "https_access" {
  name = "Allow https traffic"
  description = "Allow all https traffic for everywhere"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "tf_key" {
  key_name   = "tf_key"
  public_key = file("keys/tf_key.pub")
}

resource "aws_instance" "tf_test_ec2" {
  ami = var.aws_ami_id
  instance_type = "t3.micro"
  key_name = aws_key_pair.tf_key.key_name

  user_data = file("user_data.sh")

  vpc_security_group_ids = [
    aws_security_group.ssh_access.id,
    aws_security_group.http_access.id,
    aws_security_group.https_access.id
  ]
}