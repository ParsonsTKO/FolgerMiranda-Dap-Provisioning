module "dap_stagingclient_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} Client Staging"
  cluster = "${module.ecs.cluster}"
  desired = 1
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    container_name = "Web"
    container_port = 80
    priority = 120
    condition_field  = "host-header"
    condition_values = "staging.miranda.folger.edu,staging.collections.folger.edu"
  }

  definition_file = "files/ecs/folgerdap/staging/client.json"
  definition_vars {
      graphql-endpoint = "https://server.staging.collections.folger.edu"
      manifest-endpoint = "https://server.staging.collections.folger.edu"
      apisession-endpoint = "https://server.staging.collections.folger.edu"
      region = "${var.aws["region"]}"
      web-image = "${module.dap_productionclient_service.repositories["web-image"]}"
      app-image = "${module.dap_productionclient_service.repositories["app-image"]}"
      web-version = "master"
      app-version = "master"
  }

  tags {
    App = "${local.name}"
    Environment = "Staging"
    Service = "Client"
  }
}

# Services for Staging Server - Client
module "dap_stagingserver_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} Server Staging"
  cluster = "${module.ecs.cluster}"
  desired = 1
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    priority = 110
    container_name = "Web"
    container_port = 80
    condition_field  = "host-header"
    condition_values = "server.staging.miranda.folger.edu,server.staging.collections.folger.edu"
  }

  definition_file = "files/ecs/folgerdap/staging/server.json"
  definition_vars {
    db_name = "folgerdap_staging"
    db_password = "${var.db_password}"
    elasticsearch-index = "folgersdap_staging"
    region = "${var.aws["region"]}"
    web-image = "${module.dap_productionserver_service.repositories["web-image"]}"
    app-image = "${module.dap_productionserver_service.repositories["app-image"]}"    
    web-version = "master"
    app-version = "master"
    sqs_queue = "${module.stagingassetsretrieval_sqs.url}"
    assets_content_bucket = "${module.assets_content_staging.name}"
    assets_content_bucket_endpoint = "https://${module.assets_content_staging.domain}"
    ses_smtp_user = "${var.ses_smtp_user}"
    ses_smtp_password = "${var.ses_smtp_password}"
  }

  tags {
    App = "${local.name}"
    Environment = "Staging"
    Service = "Server"
  }
}

module "dap_stagingimportrecords_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} ImportRecords Staging"
  definition_file = "files/ecs/folgerdap/staging/importrecords.json"
  definition_vars {
      app-image = "${module.dap_server_service.repositories["app-image"]}"
      app-version = "master"
      db_name = "folgerdap_staging"
      db_password = "${var.db_password}"
      elasticsearch-index = "folgersdap_staging"
      region = "${var.aws["region"]}"
      sqs_queue = "${module.stagingassetsretrieval_sqs.url}"
      source_bucket = "${module.stagingrecords_files_source.name}"
      imported_bucket = "${module.stagingrecords_files_imported.name}"
      assets_content_bucket_endpoint = "https://${module.assets_content_staging.domain}"
  }

  tags {
    App = "${local.name}"
    Environment = "Staging"
    Service = "ImportRecords"
  }
}

module "dap_stagingassetsretrieval_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} AssetsRetrieval Staging"
  cluster = "${module.ecs.cluster}"
  desired = 1

  definition_file = "files/ecs/folgerdap/staging/assetsretrieval.json"
  definition_vars {
      app-image = "${module.dap_productionassetsretrieval_service.repositories["app-image"]}"
      app-version = "master"
      region = "${var.aws["region"]}"
      sqs_queue = "${module.stagingassetsretrieval_sqs.url}"
      assets_content_bucket = "${module.assets_content_staging.name}"
  }

  tags {
    App = "${local.name}"
    Environment = "Staging"
    Service = "AssetsRetrieval"
  }
}

module "dap_stagingiiif_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} IIIF Staging"
  cluster = "${module.ecs.cluster}"
  desired = 1
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    priority = 130
    container_name = "App"
    container_port = 8182
    condition_field  = "host-header"
    condition_values = "iiif.staging.miranda.folger.edu,iiif.staging.collections.folger.edu"
  }

  definition_file = "files/ecs/folgerdap/staging/iiif.json"
  definition_vars {
      app-image = "${module.dap_productioniiif_service.repositories["app-image"]}"
      app-version = "master"
      admin-password = "${var.iiif_password}"
      s3-bucket = "${module.assets_content_staging.name}"
      region = "${var.aws["region"]}"
  }

  tags {
    App = "${local.name}"
    Environment = "Staging"
    Service = "IIIF"
  }
}


module "stagingassetsretrieval_sqs" {
  source  = "Aplyca/sqs/aws"
  version = "0.1.0"

  name    = "${local.name} AssetsRetrieval Staging"
  description = "${local.name} AssetsRetrieval Staging SQS"
  retention = 1209600
  wait_time = 20
  send_roles = ["${module.dap_stagingimportrecords_service.role}", "${module.dap_stagingserver_service.role}"]
  recieve_roles = ["${module.dap_stagingassetsretrieval_service.role}"]
  max_recieve_count = 3

  tags {
    App = "${local.name} AssetsRetrieval"
    Environment = "Staging"
  }
}

module "assets_content_staging" {
  source  = "Aplyca/s3/aws"
  version = "0.1.3"

  name   = "${local.name} Assets Staging"
  acl = "public-read"
  read_roles = ["${module.dap_stagingiiif_service.role}", "${module.dap_stagingserver_service.role}", "${module.dap_stagingassetsretrieval_service.role}"]
  write_roles = ["${module.dap_stagingassetsretrieval_service.role}"]
  website = [{
    index_document = "index.html"
    error_document = "index.html"
  }]

  cors_allowed_origins = ["*"]
  cors_allowed_headers = ["*"]
  cors_allowed_methods = ["GET"]
  cors_expose_headers  = ["ETag"]
  cors_max_age_seconds = "0"

  tags {
    App = "${local.name} Assets"
    Environment = "Staging"
  }
}

module "static_content_staging" {
  source  = "Aplyca/s3/aws"
  version = "0.1.0"

  name   = "${local.name} Static Staging"
  acl = "public-read"

  website = [{
    index_document = "index.html"
    error_document = "index.html"
  }]

  cors_allowed_origins = ["*"]
  cors_allowed_headers = ["*"]
  cors_allowed_methods = ["GET"]
  cors_expose_headers  = ["ETag"]
  cors_max_age_seconds = "0"

  tags {
    App = "${local.name} Static"
    Environment = "Staging"
  }
}

module "stagingrecords_files_source" {
  source  = "Aplyca/s3/aws"
  version = "0.1.4"

  name   = "${local.name} RecordFiles Source Staging"
  read_roles = ["${module.dap_stagingimportrecords_service.role}"]
  write_roles = ["${module.dap_stagingimportrecords_service.role}"]
  description = "${local.name} Record Files Source Staging"
  tags {
    App = "${local.name}"
  }
}

module "stagingrecords_files_imported" {
  source  = "Aplyca/s3/aws"
  version = "0.1.4"

  name   = "${local.name} RecordFiles Imported Staging"
  write_roles = ["${module.dap_stagingimportrecords_service.role}"]
  description = "${local.name} RecordFiles Imported Staging"
  tags {
    App = "${local.name}"
  }
}
