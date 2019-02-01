variable "name" {
  description = "Name prefix for all VPC resources."
  default     = "App"
}

variable "repositories" {
  description = "List of repositories"
  default     = []
}

variable "cluster_role" {
  description = "Cluster instances role name"
  default     = ""
}
