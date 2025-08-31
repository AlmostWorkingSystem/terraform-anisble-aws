resource "aws_iam_user" "this" {
  name = var.user_name
}

resource "aws_iam_access_key" "this" {
  count = var.create_access_key ? 1 : 0
  user  = aws_iam_user.this.name
}

# Attach managed policies (if any)
resource "aws_iam_user_policy_attachment" "managed" {
  for_each   = { for idx, arn in var.managed_policy_arns : idx => arn }
  user       = aws_iam_user.this.name
  policy_arn = each.value
}


# Attach inline policies (if any)
resource "aws_iam_user_policy" "inline" {
  for_each = var.inline_policies
  name     = each.key
  user     = aws_iam_user.this.name
  policy   = each.value
}
