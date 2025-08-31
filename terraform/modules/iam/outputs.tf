output "user_name" {
  value = aws_iam_user.this.name
}

output "access_key_id" {
  value     = try(aws_iam_access_key.this[0].id, null)
  sensitive = true
}

output "secret_access_key" {
  value     = try(aws_iam_access_key.this[0].secret, null)
  sensitive = true
}
