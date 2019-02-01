module "dap_productionclient_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} Client Production"
  cluster = "${module.ecs.cluster}"
  desired = 2
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    container_name = "Web"
    container_port = 80
    priority = 220
    condition_field  = "host-header"
    condition_values = "production.collections.folger.edu,collections.folger.edu,miranda.folger.edu,collection.folger.edu,miranda.parsonstko.com"
  }

  repositories {
    web-image = "${local.name}/Client/Web"
    app-image = "${local.name}/Client/App"
  }

  definition_file = "files/ecs/folgerdap/production/client.json"
  definition_vars {
      graphql-endpoint = "https://server.collections.folger.edu"
      manifest-endpoint = "https://server.collections.folger.edu"
      apisession-endpoint = "https://server.collections.folger.edu"
      region = "${var.aws["region"]}"
      web-version = "master"
      app-version = "master"
  }

  tags {
    App = "${local.name}"
    Environment = "Production"
    Service = "Client"
  }
}

# Services for Production Server - Client
module "dap_productionserver_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} Server Production"
  cluster = "${module.ecs.cluster}"
  desired = 1
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    priority = 210
    container_name = "Web"
    container_port = 80
    condition_field  = "host-header"
    condition_values = "server.production.collections.folger.edu,server.collections.folger.edu,server.miranda.folger.edu,server.miranda.parsonstko.com"
  }

  repositories {
    app-image = "${local.name}/Server/App"
    web-image = "${local.name}/Server/Web"
  }

  definition_file = "files/ecs/folgerdap/production/server.json"
  definition_vars {
    db_name = "folgerdap_production"
    db_password = "${var.db_password}"
    elasticsearch-index = "folgerdap_production"
    region = "${var.aws["region"]}"
    web-version = "master"
    app-version = "master"
    sqs_queue = "${module.productionassetsretrieval_sqs.url}"
    assets_content_bucket = "${module.assets_content_production.name}"
    assets_content_bucket_endpoint = "https://assets.collections.folger.edu"
    ses_smtp_user = "${var.ses_smtp_user}"
    ses_smtp_password = "${var.ses_smtp_password}"
  }

  tags {
    App = "${local.name}"
    Environment = "Production"
    Service = "Server"
  }
}

module "dap_productionimportrecords_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} ImportRecords Production"
  definition_file = "files/ecs/folgerdap/production/importrecords.json"
  definition_vars {
      app-image = "${module.dap_server_service.repositories["app-image"]}"
      app-version = "master"
      db_name = "folgerdap_production"
      db_password = "${var.db_password}"
      elasticsearch-index = "folgerdap_production"
      region = "${var.aws["region"]}"
      sqs_queue = "${module.productionassetsretrieval_sqs.url}"
      source_bucket = "${module.productionrecords_files_source.name}"
      imported_bucket = "${module.productionrecords_files_imported.name}"
  }

  tags {
    App = "${local.name}"
    Environment = "Production"
    Service = "ImportRecords"
  }
}

module "dap_productionassetsretrieval_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} AssetsRetrieval Production"
  cluster = "${module.ecs.cluster}"
  desired = 1

  repositories {
    app-image = "${local.name}/AssetsRetrieval/App"
  }

  definition_file = "files/ecs/folgerdap/production/assetsretrieval.json"
  definition_vars {
      app-version = "master"
      region = "${var.aws["region"]}"
      sqs_queue = "${module.productionassetsretrieval_sqs.url}"
      assets_content_bucket = "${module.assets_content_production.name}"
  }

  tags {
    App = "${local.name}"
    Environment = "Production"
    Service = "AssetsRetrieval"
  }
}

module "dap_productioniiif_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} IIIF Production"
  cluster = "${module.ecs.cluster}"
  desired = 3
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    priority = 230
    container_name = "App"
    container_port = 8182
    condition_field  = "host-header"
    condition_values = "iiif.production.collections.folger.edu,iiif.miranda.folger.edu,iiif.miranda.parsonstko.com,iiifadmin.miranda.parsonstko.com,iiif.collections.folger.edu"
  }

  repositories {
    app-image = "${local.name}/IIIF/App"
  }

  definition_file = "files/ecs/folgerdap/production/iiif.json"
  definition_vars {
      app-version = "master"
      admin-password = "${var.iiif_password}"
      s3-bucket = "${module.assets_content_production.name}"
      region = "${var.aws["region"]}"
  }

  tags {
    App = "${local.name}"
    Environment = "Production"
    Service = "IIIF"
  }
}

module "productionassetsretrieval_sqs" {
  source  = "Aplyca/sqs/aws"
  version = "0.1.0"

  name    = "${local.name} AssetsRetrieval Production"
  description = "${local.name} AssetsRetrieval Production SQS"
  retention = 1209600
  wait_time = 20
  send_roles = ["${module.dap_productionimportrecords_service.role}", "${module.dap_productionserver_service.role}"]
  recieve_roles = ["${module.dap_productionassetsretrieval_service.role}"]
  max_recieve_count = 3

  tags {
    App = "${local.name} AssetsRetrieval"
    Environment = "Production"
  }
}

module "productionrecords_files_source" {
  source  = "Aplyca/s3/aws"
  version = "0.1.4"

  name   = "${local.name} RecordFiles Source Production"
  read_roles = ["${module.dap_productionimportrecords_service.role}"]
  write_roles = ["${module.dap_productionimportrecords_service.role}"]  
  description = "${local.name} Record Files Source Production"
  tags {
    App = "${local.name}"
  }
}

module "productionrecords_files_imported" {
  source  = "Aplyca/s3/aws"
  version = "0.1.4"

  name   = "${local.name} RecordFiles Imported Production"
  write_roles = ["${module.dap_productionimportrecords_service.role}"]
  description = "${local.name} RecordFiles Imported Production"
  tags {
    App = "${local.name}"
  }
}

module "assets_content_production" {
  source  = "Aplyca/s3/aws"
  version = "0.1.4"

  name   = "${local.name} Assets Production"
  access_identity_arn = "${module.cdn_assets_production.access_identity_arn}"
  access_identity = true
  read_roles = ["${module.dap_productioniiif_service.role}", "${module.dap_productionserver_service.role}", "${module.dap_productionassetsretrieval_service.role}"]
  write_roles = ["${module.dap_productionassetsretrieval_service.role}"]
  versioning_enabled = true

  website = [{
    index_document = "index.html"
    error_document = "index.html"
  }]

  cors_allowed_origins = ["*"]
  cors_allowed_headers = ["*"]
  cors_allowed_methods = ["GET"]
  cors_expose_headers  = ["ETag"]
  cors_max_age_seconds = "3600"

  tags {
    App = "${local.name} Assets"
    Environment = "Production"
  }
}
module "cdn_assets_production" {
  source  = "Aplyca/cloudfront/aws"
  version = "0.1.0"

  name    = "${local.name} Assets Production"
  origin = "${module.assets_content_production.domain}"
  access_identity = true

  aliases = [
    "assets.${var.app["domain"]}",
    "assets.${var.app["app_domain"]}"    
  ]

  certificate = "${module.acm_certificate_collections_folgerdap_east.certificate_arn}"

  tags {
    App = "${local.name} Assets"
    Environment = "Production"
  }
}

module "cdn_static_production" {
  source  = "Aplyca/cloudfront/aws"
  version = "0.1.0"

  name    = "${local.name} Static Production"
  origin = "${module.static_content_production.domain}"
  access_identity = true

  aliases = [
    "static.${var.app["domain"]}",
    "static.${var.app["internal_domain"]}",
    "static.${var.app["app_domain"]}",
  ]

  certificate = "${module.acm_certificate_collections_folgerdap_east.certificate_arn}"

  tags {
    App = "${local.name} Static"
    Environment = "Production"
  }
}

module "static_content_production" {
  source  = "Aplyca/s3/aws"
  version = "0.1.4"

  name   = "${local.name} Static Prod"
  access_identity = true
  access_identity_arn = "${module.cdn_static_production.access_identity_arn}"

  website = [{
    index_document = "index.html"
    error_document = "index.html"
  }]

  cors_allowed_origins = ["*"]
  cors_allowed_headers = ["*"]
  cors_allowed_methods = ["GET"]
  cors_expose_headers  = ["ETag"]
  cors_max_age_seconds = "3600"

  tags {
    App = "${local.name} Static"
    Environment = "Production"
  }
}

