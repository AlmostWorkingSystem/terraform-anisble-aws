variable "instance_name" {
  type = string
}
variable "ami_id" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "sg_ids" {
  type = list(string)
}
variable "key_name" {
  description = "The name of the SSH key pair to use for the instance"
  type        = string
}

variable "assign_eip" {
  type        = bool
  description = "Whether to allocate and associate an Elastic IP"
  default     = false
}

variable "availability_zone" {
  type        = string
  description = "The availability zone where the instance will be launched"
  default     = "ap-south-2c"
}

variable "volume_size" {
  type    = number
  default = 10
}
