variable "name" {
  description = "Name prefix for all EC2 resources."
  default     = "App"
}

variable "subnets" {
  description = "A list of subnets to associate with."
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

variable "ami" {
  description = "AMI Id."
  default = false
}

variable "type" {
  description = "Instance type."
  default = "t2.micro"
}

variable "identifier" {
  description = "Launch configuration identifier suffix"
}

variable "min" {
  description = "Minimun number of instances in cluster."
  default = 0
}

variable "max" {
  description = "Maximun number of instances in cluster."
  default = 0
}

variable "desired" {
  description = "Desired number of instances in cluster."
  default = 0
}

variable "lb_sgs" {
  description = "A list of security groups for load balancer."
  type        = "list"
  default     = []
}

variable "lc_sgs" {
  description = "A list of security groups for launch configuration."
  type        = "list"
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  default     = {}
}

variable "asg_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = "list"
  default     = []
}

variable "stickiness" {
  description = "ALB Target Group stickiness duration"
  default     = 0
}

variable "key_name" {
  description = "Public SSH key."
  default = "EC2-key"
}

variable "deregistration_delay" {
  description = "Target Group deregistration delay."
  default = 30
}

variable "role" {
  description = "Instance role."
}

variable "certificate" {
  description = "IAM certficate"
  default = ""
}

variable "grace_period" {
  description = "ASG grace period"
  default = 300
}

variable "timeout" {
  description = "ALB idle timeout"
  default = 60
}
