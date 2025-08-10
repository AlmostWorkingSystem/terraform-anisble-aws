resource "aws_route53_record" "subdomain" {
  zone_id = "Z076900731VYLETHWJBJA" # existing hosted zone ID
  name    = "api.example.com"   # your subdomain
  type    = "A"
  ttl     = 300
  records = [aws_instance.tf_test_ec2.public_ip]    # IP or target
}