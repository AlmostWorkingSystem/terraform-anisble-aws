output "instance_public_ips" {
  description = "Public IPs of all created EC2 instances"
  value       = [for inst in module.aws_instance : inst.public_ip]
}

output "instance_ids" {
  description = "IDs of all created EC2 instances"
  value       = [for inst in module.aws_instance : inst]
}

# output "security_group_ids" {
#   description = "All security group IDs created"
#   value       = [for sg in module.security_group : sg]
# }

# output "dns_records" {
#   description = "All DNS record values created"
#   value       = module.dns.records
# }

# output "zone_id" {
#   description = "Hosted Zone ID used for DNS"
#   value       = module.dns.zone_id
# }
