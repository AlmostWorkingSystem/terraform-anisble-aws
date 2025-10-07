resource "cloudflare_dns_record" "db" {
  zone_id = var.zone_id
  name    = "db.kiet.co.in"
  content = "98.130.141.194"
  type    = "A"
  ttl     = 300
  proxied = false
  comment = "For DB"
}

resource "cloudflare_dns_record" "_db" {
  zone_id = var.zone_id
  name    = "*.db.kiet.co.in"
  content = "98.130.141.194"
  type    = "A"
  ttl     = 300
  proxied = false
  comment = "For DB Adminer and stuff"
}

resource "cloudflare_dns_record" "hub" {
  zone_id = var.zone_id
  name    = "hub.erp.kiet.co.in"
  content = "98.130.130.170"
  type    = "A"
  ttl     = 300
  proxied = false
  comment = "For ERP OpenProject"
}

resource "cloudflare_dns_record" "staging" {
  zone_id = var.zone_id
  name    = "staging.erp.kiet.co.in"
  content = "18.60.11.244"
  type    = "A"
  ttl     = 300
  proxied = false
  comment = "For Staging"
}

resource "cloudflare_dns_record" "backend_staging" {
  zone_id = var.zone_id
  name    = "backend-staging.kiet.co.in"
  content = "18.60.11.244"
  type    = "A"
  ttl     = 300
  proxied = false
  comment = "For backend_staging"
}

resource "cloudflare_dns_record" "webhooks" {
  zone_id = var.zone_id
  name    = "wh.kiet.co.in"
  content = "18.60.11.244"
  type    = "A"
  ttl     = 300
  proxied = false
  comment = "For webhooks"
}

resource "cloudflare_dns_record" "_staging" {
  zone_id = var.zone_id
  name    = "*.staging.erp.kiet.co.in"
  content = "18.60.11.244"
  type    = "A"
  ttl     = 300
  proxied = false
  comment = "For *Staging"
}
