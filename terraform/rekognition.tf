data "aws_iam_policy_document" "rekognition_access" {
  statement {
    sid    = "AllowRekognitionLivenessActions"
    effect = "Allow"

    actions = [
      "rekognition:CreateFaceLivenessSession",
      "rekognition:GetFaceLivenessSessionResults",
      "rekognition:StartFaceLivenessSession",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowFaceSearchAndDetect"
    effect = "Allow"

    actions = [
      "rekognition:SearchFacesByImage",
      "rekognition:IndexFaces",
      "rekognition:DetectFaces",
      "rekognition:ListCollections",
      "rekognition:DescribeCollection",
      "rekognition:CreateCollection",
      "rekognition:DeleteFaces",
      "rekognition:ListFaces",
      "rekognition:DeleteCollection",
    ]

    resources = ["*"]
  }
}

module "rekognition_user" {
  source            = "./modules/iam"
  user_name         = "rekognition-service-user"
  create_access_key = true

  inline_policies = {
    RekognitionFull = data.aws_iam_policy_document.rekognition_access.json
    AssumeRekognitionLivenessRole = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sts:AssumeRole"
          ]
          Resource = "arn:aws:iam::029930584218:role/RekognitionLivenessRole"
        }
      ]
    })
  }
}

module "rekognition_user_s3_bucket" {
  source = "./modules/s3"

  bucket_name         = "rekognition-user-bkt-001"
  force_destroy       = true
  block_public_policy = true
  region              = "ap-south-1"
}

resource "aws_iam_policy" "rekognition_user_s3_access" {
  name        = "rekognition-user-s3-access"
  description = "Allow rekognition-service-user to access rekognition_user bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.rekognition_user_s3_bucket.bucket_arn,
          "${module.rekognition_user_s3_bucket.bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "rekognition_user_s3_attach" {
  user       = module.rekognition_user.user_name
  policy_arn = aws_iam_policy.rekognition_user_s3_access.arn
}

# Allow the Rekognition operations to assume a role for liveness workflows.
# The role didn't exist previously (causing AssumeRole failures), so create it
# here with a trust policy that allows the service IAM user to assume it.
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "rekognition_liveness_role" {
  name = "RekognitionLivenessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${module.rekognition_user.user_name}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach Rekognition permissions to the role (from the existing policy document)
resource "aws_iam_role_policy" "rekognition_role_policy" {
  name = "RekognitionFull"
  role = aws_iam_role.rekognition_liveness_role.id

  policy = data.aws_iam_policy_document.rekognition_access.json
}

# Grant the role access to the rekognition S3 bucket (reuse the policy)
resource "aws_iam_role_policy_attachment" "rekognition_role_s3_attach" {
  role       = aws_iam_role.rekognition_liveness_role.name
  policy_arn = aws_iam_policy.rekognition_user_s3_access.arn
}




output "rekognition_user_name" {
  value       = module.rekognition_user.user_name
  description = "IAM user name for Rekognition operations"
}

output "rekognition_user_access_key_id" {
  value     = module.rekognition_user.access_key_id
  sensitive = true
}

output "rekognition_user_secret_access_key" {
  value     = module.rekognition_user.secret_access_key
  sensitive = true
}
