resource "aws_route53_record" "subdomain" {
  zone_id = var.zone_id
  name    = var.subdomain
  type    = var.type
  ttl     = var.ttl
  records = var.records
}