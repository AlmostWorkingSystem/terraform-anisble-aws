resource "cloudflare_dns_record" "db" {
  zone_id = var.zone_id
  name    = "db.kiet.co.in"
  content = "98.130.141.194"
  type    = "A"
  ttl     = 3600
  proxied = false
  comment = "For DB"
}

resource "cloudflare_dns_record" "_db" {
  zone_id = var.zone_id
  name    = "*.db.kiet.co.in"
  content = "98.130.141.194"
  type    = "A"
  ttl     = 3600
  proxied = false
  comment = "For DB Adminer and stuff"
}

resource "cloudflare_dns_record" "hub" {
  zone_id = var.zone_id
  name    = "hub.erp.kiet.co.in"
  content = "90rkyt34.up.railway.app"
  type    = "CNAME"
  ttl     = 3600
  proxied = false
  comment = "For ERP OpenProject"
}

resource "cloudflare_dns_record" "frontend" {
  zone_id = var.zone_id
  name    = "erp.kiet.co.in"
  content = "mjtnrtb9.up.railway.app"
  type    = "CNAME"
  ttl     = 3600
  proxied = false
  comment = "For frontend"
}

resource "cloudflare_dns_record" "staging" {
  zone_id = var.zone_id
  name    = "staging.erp.kiet.co.in"
  content = "18.60.11.244"
  type    = "A"
  ttl     = 3600
  proxied = false
  comment = "For Staging"
}

resource "cloudflare_dns_record" "backend_staging" {
  zone_id = var.zone_id
  name    = "backend-staging.kiet.co.in"
  content = "18.60.11.244"
  type    = "A"
  ttl     = 3600
  proxied = false
  comment = "For backend_staging"
}

resource "cloudflare_dns_record" "railway_backend" {
  zone_id = var.zone_id
  name    = "backend.kiet.co.in"
  content = "zuvnkr1k.up.railway.app"
  type    = "CNAME"
  ttl     = 3600
  proxied = false
  comment = "For railway_backend"
}

resource "cloudflare_dns_record" "uptime" {
  zone_id = var.zone_id
  name    = "uptime.kiet.co.in"
  content = "235u31od.up.railway.app"
  type    = "CNAME"
  ttl     = 3600
  proxied = false
  comment = "For uptime"
}

resource "cloudflare_dns_record" "_staging" {
  zone_id = var.zone_id
  name    = "*.staging.erp.kiet.co.in"
  content = "18.60.11.244"
  type    = "A"
  ttl     = 3600
  proxied = false
  comment = "For *Staging"
}

locals {
  s3_buckets = {
    "erp3-attachments" = {
    },
  }
}


module "s3_buckets" {
  for_each = local.s3_buckets
  source   = "./modules/s3"

  bucket_name = each.key
}
