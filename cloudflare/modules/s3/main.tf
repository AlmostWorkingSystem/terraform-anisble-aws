terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

resource "cloudflare_r2_bucket" "this" {
  name       = var.bucket_name
  account_id = var.account_id
  location   = "APAC"
}
