variable "user_name" {
  type = string
}

variable "create_access_key" {
  type    = bool
  default = true
}

variable "managed_policy_arns" {
  type    = list(string)
  default = []
}

variable "inline_policies" {
  type    = map(string) # map of { policy_name = json_policy }
  default = {}
}
