variable "subdomain" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "ttl" {
  type    = number
  default = 300
}

variable "records" {
  type    = list(string)
}

variable "type" {
  type    = string
  default = "A"
}