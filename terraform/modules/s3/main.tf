resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  region        = var.region
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket              = aws_s3_bucket.this.id
  block_public_acls   = var.block_public_policy
  block_public_policy = var.block_public_policy
  region              = var.region
}

# resource "aws_s3_bucket_versioning" "this" {
#   bucket = aws_s3_bucket.this.id

#   versioning_configuration {
#     mfa_delete = "Disabled"
#     status     = "Disabled"
#   }
# }
