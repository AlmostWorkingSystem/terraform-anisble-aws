resource "cloudflare_dns_record" "hub" {
  zone_id = var.zone_id
  name    = "hub.erp.kiet.co.in"
  content = "90rkyt34.up.railway.app"
  type    = "CNAME"
  ttl     = 3600
  proxied = false
  comment = "For ERP OpenProject"
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

resource "cloudflare_dns_record" "adminer" {
  zone_id = var.zone_id
  name    = "adminer.kiet.co.in"
  content = "7djnsxad.up.railway.app"
  type    = "CNAME"
  ttl     = 3600
  proxied = false
  comment = "For adminer"
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
