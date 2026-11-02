# DNS records in the kiet.co.in zone. Synced with live Cloudflare on 2 November 2026.
# ttl = 1 means "Auto".

resource "cloudflare_dns_record" "hub" {
  zone_id = var.zone_id
  name    = "hub.erp.kiet.co.in"
  content = "90rkyt34.up.railway.app"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For ERP OpenProject"
}

resource "cloudflare_dns_record" "railway_backend" {
  zone_id = var.zone_id
  name    = "backend.kiet.co.in"
  content = "zuvnkr1k.up.railway.app"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For railway_backend"
}

resource "cloudflare_dns_record" "uptime" {
  zone_id = var.zone_id
  name    = "uptime.kiet.co.in"
  content = "235u31od.up.railway.app"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For uptime"
}

resource "cloudflare_dns_record" "adminer" {
  zone_id = var.zone_id
  name    = "adminer.kiet.co.in"
  content = "7djnsxad.up.railway.app"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For adminer"
}

resource "cloudflare_dns_record" "cdn" {
  zone_id = var.zone_id
  name    = "cdn.kiet.co.in"
  content = "d2m95jyd8dhek0.cloudfront.net"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For cdn"
}

resource "cloudflare_dns_record" "cdn_validation" {
  zone_id = var.zone_id
  name    = "_714bc8f9922246cac119bbb33b1f57aa.cdn.kiet.co.in"
  content = "_633757690836f1f7fd9c0f512f9ef8e5.jkddzztszm.acm-validations.aws"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For cdn validation"
}

resource "cloudflare_dns_record" "cdn_staging" {
  zone_id = var.zone_id
  name    = "cdn.staging.kiet.co.in"
  content = "d1uavadcwht6y8.cloudfront.net"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For staging cdn"
}

resource "cloudflare_dns_record" "cdn_validation_staging" {
  zone_id = var.zone_id
  name    = "_f8337f9576d6609e4b5e430f75c062f4.cdn.staging.kiet.co.in"
  content = "_db995df678308735a9784559a816608c.jkddzztszm.acm-validations.aws"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For cdn staging validation"
}

resource "cloudflare_dns_record" "railway_staging" {
  zone_id = var.zone_id
  name    = "railway.staging.kiet.co.in"
  content = "l1kpav87.up.railway.app"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For railway staging"
}

resource "cloudflare_dns_record" "staging_backend" {
  zone_id = var.zone_id
  name    = "backend.staging.kiet.co.in"
  content = "efrv8rxe.up.railway.app"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = "For staging backend"
}

resource "cloudflare_dns_record" "staging_db" {
  zone_id = var.zone_id
  name    = "db.staging.kiet.co.in"
  content = "47.131.17.83"
  type    = "A"
  ttl     = 1
  proxied = false
  comment = "For staging db"
}

resource "cloudflare_dns_record" "staging_server" {
  zone_id = var.zone_id
  name    = "server.staging.kiet.co.in"
  content = "13.213.200.14"
  type    = "A"
  ttl     = 1
  proxied = false
  comment = "For staging db"
}
