# VPC configuration. All resources will be created inside this VPC
module "vpc" {
  source = "modules/vpc"
  name   = "${local.name}"
  env   = "ECS Cluster"
  # CIDR for the VPC
  cidr   = "172.32.0.0/16"
  # Subnet CIDR configuration
  newbits  = 8
  netnum  = 0
  ssh_open = ["52.4.7.245/32"]
  http_open = ["0.0.0.0/0"]
  https_open = ["0.0.0.0/0"]
  ephemeral_open = ["0.0.0.0/0"]
  azs     = "${local.azs}"
  tags {
    App = "${local.name}"
    Environment = "${local.env}"
  }
}

module "efs" {
  source  = "Aplyca/efs/aws"

  name    = "${local.name} ${local.env}"
  vpc_id  = "${module.vpc.vpc_id}"
  subnets = "${module.vpc.subnet_ids}"
  access_sg_ids = ["${module.ec2.cluster_sg}"]

  tags {
    App = "${local.name}"
    Environment = "${local.env}"
  }
}

module "ec2" {
  source  = "modules/ec2"

  name = "${local.name} ${local.env}"
  subnets = "${module.vpc.subnet_ids}"

  identifier = "${local.version}"
  ami = "${var.app["ami"]}"
  type = "m4.xlarge"
  # SSH Key name to use in the instance
  key_name = "${var.app["public_key_name"]}"
  lb_sgs = ["${module.vpc.web_sg}"]
  lc_sgs = []
  # Cluster size configuration
  min = "${var.app["cluster_size"] == "" ? 1 : var.app["cluster_size"] }"
  max = "${var.app["cluster_size"] == "" ? 1 : var.app["cluster_size"] }"
  desired = "${var.app["cluster_size"] == "" ? 1 : var.app["cluster_size"] }"
  stickiness = 0
  deregistration_delay = 3
  grace_period = 0
  timeout = 180
  role = "${module.iam.role}"
  tags {
    App = "${local.name}"
    Environment = "${local.env}"
  }

  certificate = "${module.acm_certificate_collections_folgerdap.certificate_arn}"

  asg_tags = [{
    key                 = "Environment"
    value               = "${local.env}"
    propagate_at_launch = true
  },{
    key                 = "App"
    value               = "${local.name}"
    propagate_at_launch = true
  },{
    key                 = "Version"
    value               = "${local.version}"
    propagate_at_launch = true
  }]
}

# Web module configuration. This module will create the necessary subnets, Build machine and DNS zone.
module "ecs" {
  source  = "modules/ecs_cluster"

  # Name of the Build instance.
  name    = "${local.name}"
  cluster_role = "${module.iam.role}"
}

module "database" {
  source  = "Aplyca/rds/aws"
  version = "1.1.4"

  name    = "${local.name} Prod"
  engine = "postgres"
  engine_version = 9.6
  vpc_id  = "${module.vpc.vpc_id}"
  newbits  = 10
  netnum  = 12
  azs     = "${local.azs}"
  rt_id   = "${module.vpc.rt_default_id}"
  access_sg_ids = ["${module.ec2.cluster_sg}"]
  access_cidrs = "${module.vpc.subnets_cidr}"
  type = "db.t2.xlarge"
  storage = 50
  db_user = "folgerdap"
  db_name = "folgerdap"
  db_password = "${var.db_password}"
  db_snapshot_identifier  = "folgerdap-recover-20180724"
  port = 5432

  tags {
    App = "${local.name}"
    Environment = "${local.env}"
  }
}

module "acm_certificate_collections_folger" {
  source  = "Aplyca/acm/aws"
  version = "0.1.3"

  domain   = "*.${var.app["app_domain"]}"
  alternative_domains = [
    "*.${var.app["domain"]}",
    "*.aws.${var.app["domain"]}",
    "*.staging.${var.app["domain"]}",
    "${var.app["internal_domain"]}",
    "*.${var.app["internal_domain"]}",
    "*.aws.${var.app["internal_domain"]}",
    "*.aws.${var.app["app_domain"]}",
    "*.staging.${var.app["app_domain"]}",   
    "*.${var.app["root_domain"]}" 
  ]
  zone_ids = [
    "${module.r53_collections.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda_parsonstko.zone_id}",
    "${module.r53_miranda_parsonstko.zone_id}",
    "${module.r53_miranda_parsonstko.zone_id}",
    "${module.r53_collections.zone_id}",
    "${module.r53_collections.zone_id}"
  ]

  validate = false
  tags {
    Name = "${local.name} DAP Collections OLD"
    App = "${local.name}"
    Environment = "ECS"
  }
}

module "acm_certificate_collections_folger_east" {
  source  = "Aplyca/acm/aws"
  version = "0.1.3"

  providers = {
    aws = "aws.east"
  }

  domain   = "*.${var.app["app_domain"]}"
  alternative_domains = [
    "*.${var.app["domain"]}",
    "*.aws.${var.app["domain"]}",
    "*.staging.${var.app["domain"]}",
    "${var.app["internal_domain"]}",
    "*.${var.app["internal_domain"]}",
    "*.aws.${var.app["internal_domain"]}",
    "*.aws.${var.app["app_domain"]}",
    "*.staging.${var.app["app_domain"]}",   
    "*.${var.app["root_domain"]}" 
  ]
  zone_ids = [
    "${module.r53_collections.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda_parsonstko.zone_id}",
    "${module.r53_miranda_parsonstko.zone_id}",
    "${module.r53_miranda_parsonstko.zone_id}",
    "${module.r53_collections.zone_id}",
    "${module.r53_collections.zone_id}"
  ]

  validate = false
  tags {
    Name = "${local.name} DAP Collections OLD"
    App = "${local.name}"
    Environment = "ECS"
  }
}

module "acm_certificate_collections_folgerdap" {
  source  = "Aplyca/acm/aws"
  version = "0.1.3"

  domain   = "*.${var.app["app_domain"]}"
  alternative_domains = [
    "*.${var.app["domain"]}",
    "*.aws.${var.app["domain"]}",
    "*.staging.${var.app["domain"]}",  
    "*.aws.${var.app["app_domain"]}",
    "*.staging.${var.app["app_domain"]}",
    "*.production.${var.app["app_domain"]}",   
    "*.${var.app["root_domain"]}" 
  ]
  zone_ids = [
    "${module.r53_collections.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_collections.zone_id}",
    "${module.r53_collections.zone_id}",
    "${module.r53_collections.zone_id}"
  ]

  validate = false
  tags {
    Name = "${local.name} DAP Collections"
    App = "${local.name}"
    Environment = "ECS"
  }
}

module "acm_certificate_collections_folgerdap_east" {
  source  = "Aplyca/acm/aws"
  version = "0.1.3"

  providers = {
    aws = "aws.east"
  }

  domain   = "*.${var.app["app_domain"]}"
  alternative_domains = [
    "*.${var.app["domain"]}",
    "*.aws.${var.app["domain"]}",
    "*.staging.${var.app["domain"]}",
    "*.aws.${var.app["app_domain"]}",
    "*.staging.${var.app["app_domain"]}", 
    "*.production.${var.app["app_domain"]}",       
    "*.${var.app["root_domain"]}" 
  ]
  zone_ids = [
    "${module.r53_collections.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_miranda.zone_id}",
    "${module.r53_collections.zone_id}",
    "${module.r53_collections.zone_id}",    
    "${module.r53_collections.zone_id}"
  ]

  validate = false
  tags {
    Name = "${local.name} DAP Collections"
    App = "${local.name}"
    Environment = "ECS"
  }
}

module "cdn_services" {
  source  = "Aplyca/cloudfront/aws"
  version = "0.1.1"
  name    = "${local.name} ${local.env}"
  origin = "lb.aws.${var.app["app_domain"]}"
  aliases = [
    "${var.app["domain"]}",
    "iiif.${var.app["domain"]}",
    "client.${var.app["domain"]}",
    "server.${var.app["domain"]}",
    "staging.${var.app["domain"]}",
    "server.staging.${var.app["domain"]}",
    "iiif.staging.${var.app["domain"]}",    
    "${var.app["internal_domain"]}",
    "*.${var.app["internal_domain"]}",
    "${var.app["app_domain"]}",
    "*.${var.app["app_domain"]}",
    "*.staging.${var.app["app_domain"]}",
    "production.${var.app["app_domain"]}",
    "*.production.${var.app["app_domain"]}",            
    "collection.folger.edu"   
  ]
  custom_origin_config = [{
    http_port = 80
    https_port = 443
    origin_protocol_policy = "https-only"
    origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    origin_read_timeout = 60
  }]
  forwarded_headers = ["Host", "Authorization", "Origin"]
  default_ttl = 0

  tags {
    App = "${local.name}"
    Environment = "${local.env}"
  }
  certificate = "${module.acm_certificate_collections_folgerdap_east.certificate_arn}"
}

module "cluster_syslog" {
  source  = "Aplyca/cloudwatchlogs/aws"
  version = "0.1.0"

  name    = "${local.name} ECSCluster Syslog"
  description = "${local.name} ECSCluster syslog"
  role = "${module.iam.role}"
  tags {
    App = "${local.name}"
    Log = "ECSCluster Syslog"
    Environment = "Prod"
  }
}

module "iam" {
  source  = "modules/iam"

  name    = "${local.name} ${local.env} Cluster"
  description = "ECS Cluster instaces role"
  tags {
    App = "${local.name}"
    Environment = "${local.env}"
  }
}

module "search" {
  source  = "Aplyca/elasticsearch/aws"
  version = "0.2.4"

  name    = "${local.name} Prod"
  es_version = 5.3
  vpc_id  = "${module.vpc.vpc_id}"
  newbits  = 10
  netnum  = 16
  azs     = ["${element(local.azs, 0)}"]
  access_sg_ids = ["${module.ec2.cluster_sg}"]
  access_cidrs = "${module.vpc.subnets_cidr}"
  storage = 25
  enable_logs = true

  tags {
    App = "${local.name}"
    Environment = "Prod"
  }
}

# Route53 module configuration. This module will create the necessary DNS records for 
module "r53_miranda_parsonstko" {
  source  = "Aplyca/route53/aws"
  version = "0.1.1"

  description = "DNS records zone for Miranda ParsonsTKO"
  domain = "${var.app["internal_domain"]}"
  records = {
    names = [
      "iiif.",
      "server.",
      "static.",
      "db.aws.",
      "efs.aws.",
      "es.aws.",
      "pga."
    ]
    types = [
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME"
    ]
    ttls = [
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600"
    ]
    values = [
      "cdn.aws.${var.app["internal_domain"]}",
      "cdn.aws.${var.app["internal_domain"]}",
      "static.aws.${var.app["internal_domain"]}",
      "folgerdap-prod.cjkmy1fm5cbp.us-east-2.rds.amazonaws.com",
      "${module.efs.efs_dns}",
      "${module.search.endpoint}",
      "lb.aws.${var.app["internal_domain"]}"
    ]
  }

  alias = {
    names = [
      "",
      "cdn.aws.",
      "lb.aws.",
      "iiifadmin.",
      "static.aws."
    ]
    values = [
      "${module.cdn_services.distribution_domain}",
      "${module.cdn_services.distribution_domain}",
      "${module.ec2.lb_cname}",
      "${module.ec2.lb_cname}",
      "${module.cdn_static_production.distribution_domain}",
    ]
    zones_id = [
      "${module.cdn_services.distribution_zone_id}",
      "${module.cdn_services.distribution_zone_id}",
      "${module.ec2.lb_zone_id}",
      "${module.ec2.lb_zone_id}",
      "${module.cdn_static_production.distribution_zone_id}",
    ]
  }
}

# Route53 module configuration. This module will create the necessary DNS records for miranda.folger.edu
module "r53_miranda" {
  source  = "Aplyca/route53/aws"
  version = "0.1.1"

  description = "DNS records zone for Miranda"
  domain = "${var.app["domain"]}"
  records = {
    names = [
      "iiif.",
      "client.",
      "server.",
      "static.",
      "staging.",
      "*.staging.",
      "assets."
    ]
    types = [
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME"
    ]
    ttls = [
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600"
    ]
    values = [
      "cdn.aws.${var.app["domain"]}",
      "cdn.aws.${var.app["domain"]}",
      "cdn.aws.${var.app["domain"]}",
      "static.aws.${var.app["domain"]}",
      "cdn.aws.${var.app["domain"]}",
      "staging.${var.app["domain"]}",
      "assets.aws.${var.app["domain"]}"
    ]
  }

  alias = {
    names = [
      "",
      "cdn.aws.",
      "lb.aws.",
      "iiifadmin.",
      "static.aws.",
      "assets.aws."
    ]
    values = [
      "${module.cdn_services.distribution_domain}",
      "${module.cdn_services.distribution_domain}",
      "${module.ec2.lb_cname}",
      "${module.ec2.lb_cname}",
      "${module.cdn_static_production.distribution_domain}",
      "${module.cdn_assets_production.distribution_domain}"
    ]
    zones_id = [
      "${module.cdn_services.distribution_zone_id}",
      "${module.cdn_services.distribution_zone_id}",
      "${module.ec2.lb_zone_id}",
      "${module.ec2.lb_zone_id}",
      "${module.cdn_static_production.distribution_zone_id}",
      "${module.cdn_assets_production.distribution_zone_id}"
    ]
  }

}

# Route53 module configuration. This module will create the necessary DNS records for collections.folger.edu
module "r53_collections" {
  source  = "Aplyca/route53/aws"
  version = "0.1.1"

  description = "DNS records zone for Collections"
  domain = "${var.app["app_domain"]}"
  records = {
    names = [
      "iiif.",
      "client.",
      "server.",
      "static.",
      "staging.",
      "*.staging.",
      "assets.",
      "db.aws.",
      "efs.aws.",
      "es.aws.",
      "pga.",
      "production.",
      "*.production."      
    ]
    types = [
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME",
      "CNAME"     
    ]
    ttls = [
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600",
      "3600"
    ]
    values = [
      "cdn.aws.${var.app["app_domain"]}",
      "cdn.aws.${var.app["app_domain"]}",
      "cdn.aws.${var.app["app_domain"]}",
      "static.aws.${var.app["app_domain"]}",
      "cdn.aws.${var.app["app_domain"]}",
      "staging.${var.app["app_domain"]}",
      "assets.aws.${var.app["app_domain"]}",
      "${module.database.address}",
      "${module.efs.efs_dns}",
      "${module.search.endpoint}",
      "lb.aws.${var.app["internal_domain"]}",
      "cdn.aws.${var.app["app_domain"]}",
      "production.${var.app["app_domain"]}",      
    ]
  }

  alias = {
    names = [
      "",
      "cdn.aws.",
      "lb.aws.",
      "static.aws.",
      "assets.aws."
    ]
    values = [
      "${module.cdn_services.distribution_domain}",
      "${module.cdn_services.distribution_domain}",
      "${module.ec2.lb_cname}",
      "${module.cdn_static_production.distribution_domain}",
      "${module.cdn_assets_production.distribution_domain}"
    ]
    zones_id = [
      "${module.cdn_services.distribution_zone_id}",
      "${module.cdn_services.distribution_zone_id}",
      "${module.ec2.lb_zone_id}",
      "${module.cdn_static_production.distribution_zone_id}",
      "${module.cdn_assets_production.distribution_zone_id}"
    ]
  }

}