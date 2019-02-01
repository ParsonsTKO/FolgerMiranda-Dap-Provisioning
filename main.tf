##########################
# Stack general settings #
##########################
variable "app" {
  default = {
    # Prefix to all resources with the project or website name
    name = "FolgerDAP"
    # Environment will be added to all resources
    env = "ECS"
    # Amount of Availability Zones (AZ) where the respurces will be deployed for high availability.
    azs = 3
    # Domain name used to create the DNS zone for the Website and upload the SSL/TLS certificates used in the Load Balancer. A folder with the same domain name containing the certificates should be present in the `files` directory, e.g.: `files/acc-cloud-plastics.org`
    domain = "miranda.folger.edu"
    app_domain = "collections.folger.edu"    
    root_domain = "folger.edu"
    internal_domain = "miranda.parsonstko.com"
    # Name of the public key in EC2.
    public_key_name = "20180331"
    # AMI used for machines in the Cluster
    ami = "ami-0307f7ccf6ea35750"
    # Number of instances in the cluster
    cluster_size = 4
    # Version of the deployment, this is used by the Launch Configuration of the website.
    version = "2018-12-18_21-00"
  }
}

# AWS configuration
variable "aws" {
  default = {
    # AWS region where the resources will be created
    region = "us-east-2"
  }
}

provider "aws" {
  version = "1.51.0"
  region     = "${var.aws["region"]}"
}

provider "aws" {
  version = "1.51.0"
  region     = "us-east-1"
  alias = "east"
}

data "aws_availability_zones" "azs" {}

locals {
  name = "${upper(var.app["name"])}"
  env = "${title(var.app["env"])}"
  version = "${var.app["version"]}"
  azs = "${slice(data.aws_availability_zones.azs.names, 0, var.app["azs"])}"
}
