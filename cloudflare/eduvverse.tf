# Email DNS for kiet.eduvverse.com (eduvverse.com zone). AWS side: ../terraform/email.tf.
# Created through the Cloudflare API on 2 November 2026; the import blocks adopt them on the
# next apply (then delete the import blocks).

variable "eduvverse_zone_id" {
  description = "Cloudflare zone id of eduvverse.com"
  type        = string
  default     = "95e71887de0b54773c842983787684da"
}

locals {
  # SES Easy DKIM tokens: terraform -chdir=../terraform output email_dns_records
  kiet_eduvverse_dkim = {
    dkim_1 = "hwimfnptrhwendxpr5g2jdqodfalf446"
    dkim_2 = "4u4lu5azg655wusv4lvu52u4lgk425il"
    dkim_3 = "qri6mmj7syhy5zgod3xda6u2nsaybybv"
  }
}

resource "cloudflare_dns_record" "kiet_eduvverse_dkim" {
  for_each = local.kiet_eduvverse_dkim
  zone_id  = var.eduvverse_zone_id
  name     = "${each.value}._domainkey.kiet.eduvverse.com"
  content  = "${each.value}.dkim.amazonses.com"
  type     = "CNAME"
  ttl      = 1
  proxied  = false
  comment  = "SES DKIM for kiet.eduvverse.com (managed in terraform-anisble-aws/cloudflare)"
}

# Mail for @kiet.eduvverse.com goes to SES receiving in ap-south-1
resource "cloudflare_dns_record" "kiet_eduvverse_mx" {
  zone_id  = var.eduvverse_zone_id
  name     = "kiet.eduvverse.com"
  content  = "inbound-smtp.ap-south-1.amazonaws.com"
  type     = "MX"
  priority = 10
  ttl      = 1
  proxied  = false
  comment  = "SES receiving for kiet.eduvverse.com (managed in terraform-anisble-aws/cloudflare)"
}

import {
  to = cloudflare_dns_record.kiet_eduvverse_dkim["dkim_1"]
  id = "95e71887de0b54773c842983787684da/b8c27367494b7752708b243194737aac"
}

import {
  to = cloudflare_dns_record.kiet_eduvverse_dkim["dkim_2"]
  id = "95e71887de0b54773c842983787684da/98ab9eebe43258a88cdaaffc32bbcd1d"
}

import {
  to = cloudflare_dns_record.kiet_eduvverse_dkim["dkim_3"]
  id = "95e71887de0b54773c842983787684da/cca8ff81502a591f66edba8eef3fef33"
}

import {
  to = cloudflare_dns_record.kiet_eduvverse_mx
  id = "95e71887de0b54773c842983787684da/d2c067691a8f2caa106c3084a0417dd5"
}
