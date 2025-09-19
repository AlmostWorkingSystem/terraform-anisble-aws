resource "aws_eip" "this" {
  count = var.assign_eip ? 1 : 0

  tags = {
    Name = "${var.instance_name}-eip"
  }
}

resource "aws_eip_association" "this" {
  count = var.assign_eip ? 1 : 0

  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [for sg in var.sg_ids : sg]
  key_name               = var.key_name
  availability_zone      = var.availability_zone

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = var.instance_name
  }
}
