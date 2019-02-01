variable "name" {
  description = "Name prefix for all VPC resources."
  default     = "App"
}

variable "env" {
  description = "Name prefix for all VPC resources."
  default     = "Prod"
}

variable "cidr" {
  description = "A CIDR for the VPC."
  default     = "172.0.0.0/16"
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  default     = {}
}

variable "ssh_open" {
  description = "CIDR to open port 22 for SSH"
  type        = "list"
  default     = []
}

variable "http_open" {
  description = "CIDR to open port 80 for HTTP"
  type        = "list"
  default     = []
}

variable "https_open" {
  description = "CIDR to open port 443 for HTTPS"
  type        = "list"
  default     = []
}

variable "ephemeral_open" {
  description = "CIDR to open ephemarl ports from 1024 to 65535"
  type        = "list"
  default     = []
}

variable "azs" {
  description = "A list of availability zones to associate with."
  type        = "list"
  default     = []
}

variable "newbits" {
  description = "newbits in the cidrsubnet function."
  default = 26
}

variable "netnum" {
  description = "netnum in the cidrsubnet function."
  default = 0
}
