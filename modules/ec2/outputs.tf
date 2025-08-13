# output "public_ip" {
#   value = aws_instance.ec2.public_ip
# }

output "public_ip" {
  value       = var.assign_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
  description = "Public IP address of the instance"
}
