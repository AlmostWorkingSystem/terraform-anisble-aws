//pick bucket and dynamodb from Justfile
terraform {
  backend "s3" {
    bucket         = "tf-erp-state-bkt"
    key            = "staging/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}
