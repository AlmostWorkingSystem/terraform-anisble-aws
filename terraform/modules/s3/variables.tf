variable "bucket_name" {
  type = string
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "aws_s3_bucket_versioning" {
  type        = string
  description = "Versioning state of the S3 bucket. Allowed values: Enabled, Suspended, Disabled"
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Suspended", "Disabled"], var.aws_s3_bucket_versioning)
    error_message = "aws_s3_bucket_versioning must be one of: Enabled, Suspended, Disabled."
  }
}

variable "block_public_policy" {
  default = true
  type    = bool
}

variable "region" {
  description = "The AWS region where the S3 bucket will be created."
  type        = string
  default     = "ap-south-2"
}
