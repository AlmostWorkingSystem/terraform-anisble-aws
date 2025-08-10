output "sg_http_id" {
  value = aws_security_group.allow-http.id    
}

output "sg_https_id" {
  value = aws_security_group.allow-https.id
}

output "sg_ssh_id" {
  value = aws_security_group.allow-ssh.id
}