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

resource "cloudflare_dns_record" "cdn" {
  zone_id = var.zone_id
  name    = "cdn.kiet.co.in"
  content = "d21m4rf92yeikl.cloudfront.net"
  type    = "CNAME"
  ttl     = 3600
  proxied = false
  comment = "For cdn"
}

resource "cloudflare_dns_record" "cdn_validation" {
  zone_id = var.zone_id
  name    = "_714bc8f9922246cac119bbb33b1f57aa.cdn.kiet.co.in"
  content = "_633757690836f1f7fd9c0f512f9ef8e5.jkddzztszm.acm-validations.aws"
  type    = "CNAME"
  ttl     = 3600
  proxied = false
  comment = "For cdn validation"
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
