# output "public_ip" {
#   value = aws_instance.ec2.public_ip
# }

output "instance_name" {
  description = "EC2 instance Name tag"
  value       = aws_instance.this.tags["Name"]
}

output "public_ip" {
  value       = var.assign_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
  description = "Public IP address of the instance"
}

output "private_ip" {
  value       = aws_instance.this.private_ip
  description = "Private IP address of the instance"
}
