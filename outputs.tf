output "instance_public_ip" {
  value = aws_instance.tf_test_ec2.public_ip
}

output "instance_id" {
  value = aws_instance.tf_test_ec2.id
}
