terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }

  backend "s3" {
    bucket                      = "cf-tf-state"
    key                         = "terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    access_key                  = "dd66ddc2d37ff67990a88c335fe0bd4b"
    secret_key                  = "e34bd7dd256543fbcfcd61be24bda6ca1b60588b393d338e3433c436f5cecb4c"
    endpoint                    = "https://d769abdb178059146893fd12fa1acb44.r2.cloudflarestorage.com"
  }
}

provider "cloudflare" {
  # API token will be read from CLOUDFLARE_API_TOKEN environment variable
  # api_key = "aPuaqLaydqM_aIqOUsLso64fsUz18H_y7LWAh4ko"
  # email   = "erp3.0@kiet.co.in"
}
