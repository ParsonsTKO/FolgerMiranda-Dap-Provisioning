variable "name" {
  description = "Name prefix for all VPC resources."
  default     = "App"
}

variable "certificate_domain" {
  description = "Certficate domain."
  default = false
}

variable "description" {
  description = "Role description"
  default = ""
}

variable "trusted" {
  description = "Trusted entity"
  default = "ec2"
}

variable "policies" {
  description = "Policies to add to Role"
  default     = []
}


variable "tags" {
  description = "A mapping of tags to assign to the resource."
  default     = {}
}
