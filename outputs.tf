output "azs" {
  value = "${local.azs}"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_ig" {
  value = "${module.vpc.ig}"
}

output "domains" {
  value = "${module.cdn_services.aliases}"
}
