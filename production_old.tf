


module "server_logs" {
  source  = "Aplyca/cloudwatchlogs/aws"
  version = "0.1.0"

  name    = "${local.name} ECSTask Server"
  role = "${module.server-task_role.role}"
  description = "${local.name} ECSTask Server"
  tags {
    App = "${local.name}"
    Log = "ECSTask Server"
    Environment = "Prod"
  }
}

module "client_logs" {
  source  = "Aplyca/cloudwatchlogs/aws"
  version = "0.1.0"

  name    = "${local.name} ECSTask Client"
  role = "${module.client-task_role.role}"
  description = "${local.name} ECSTask Client"
  tags {
    App = "${local.name}"
    Log = "ECSTask Client"
    Environment = "Prod"
  }
}

module "dap_iiif_service" {
  source  = "modules/ecs_deploy"
  name    = "${local.name} IIIF"
  cluster = "${module.ecs.cluster}"
  desired = 0
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    priority = 80
    container_name = "App"
    container_port = 8182
    condition_field  = "host-header"
    condition_values = "oldsite.iiif.collections.folger.edu"
  }

  definition_file = "files/ecs/folgerdap/prod_old/iiif.json"
  definition_vars {
      app-image = "${module.dap_productioniiif_service.repositories["app-image"]}"    
      app-version = "0.1.4"
  }
  volumes = [{
    name      = "FOLGERDAP-Images"
    host_path = "/mnt/efs/folgerdap/dap_images"
  }]
  tags {
    App = "${local.name}"
    Environment = "${local.env}"
    Service = "IIIF"
  }
}

module "dap_client_service" {
  source  = "modules/ecs_deploy"
  name    = "${local.name} Client"
  cluster = "${module.ecs.cluster}"
  desired = 0
  task_role = "${module.client-task_role.role_arn}"
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    container_name = "Web"
    container_port = 80
    priority = 100
    condition_field  = "host-header"
    condition_values = "oldsite.collections.folger.edu"
  }

  definition_file = "files/ecs/folgerdap/prod_old/client.json"
  definition_vars {
      region = "${var.aws["region"]}"
      log_group = "${module.client_logs.name}"
      web-image = "${module.dap_productionclient_service.repositories["web-image"]}"
      app-image = "${module.dap_productionclient_service.repositories["app-image"]}"      
      web-version = "0.2.0"
      app-version = "0.4.13"
  }
  tags {
    App = "${local.name}"
    Environment = "${local.env}"
    Service = "Client"
  }
}

module "dap_server_service" {
  source  = "modules/ecs_deploy"
  name    = "${local.name} Server"
  cluster = "${module.ecs.cluster}"
  desired = 0
  task_role = "${module.server-task_role.role_arn}"
  balancer {
    vpc_id  = "${module.vpc.vpc_id}"
    listener_http = "${module.ec2.listener_http}"
    listener_https = "${module.ec2.listener_https}"
    priority = 90
    container_name = "Web"
    container_port = 80
    condition_field  = "host-header"
    condition_values = "oldsite.server.collections.folger.edu"
  }

  definition_file = "files/ecs/folgerdap/prod_old/server.json"
  definition_vars {
      db_password = "${var.db_password}"
      region = "${var.aws["region"]}"
      log_group = "${module.server_logs.name}"
      web-image = "${module.dap_productionserver_service.repositories["web-image"]}"
      app-image = "${module.dap_productionserver_service.repositories["app-image"]}"      
      web-version = "0.1.34"
      app-version = "0.1.31"
  }
  volumes = [{
    name      = "FOLGERDAP-Images"
    host_path = "/mnt/efs/folgerdap/dap_images"
  }]
  tags {
    App = "${local.name}"
    Environment = "${local.env}"
    Service = "Server"
  }
}

module "dap_importrecords_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} ImportRecords Prod"
  definition_file = "files/ecs/folgerdap/prod_old/importrecords.json"
  definition_vars {
      app-image = "${module.dap_server_service.repositories["app-image"]}"
      app-version = "0.1.6"
      db_password = "${var.db_password}"
      region = "${var.aws["region"]}"
      sqs_queue = "${module.assetsretrieval_sqs.url}"
  }
  tags {
    App = "${local.name} ImportRecords"
    Environment = "Prod"
  }
}

# Service for Assets retrieval
module "dap_assetsretrieval_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.1.0"

  name    = "${local.name} AssetsRetrieval Prod"
  cluster = "${module.ecs.cluster}"
  desired = 0

  definition_file = "files/ecs/folgerdap/prod_old/assetsretrieval.json"
  definition_vars {
      app-image = "${module.dap_productionassetsretrieval_service.repositories["app-image"]}"    
      app-version = "0.2.2"
      region = "${var.aws["region"]}"
      sqs_queue = "${module.assetsretrieval_sqs.url}"
  }
  volumes = [{
    name      = "FOLGERDAP-Images"
    host_path = "/mnt/efs/folgerdap/dap_images"
  }]

  tags {
    App = "${local.name} AssetsRetrieval"
    Environment = "Prod"
  }
}

module "records_files" {
  source  = "Aplyca/s3/aws"
  version = "0.1.3"

  name   = "${local.name} Record Files"
  read_roles = ["${module.dap_importrecords_service.role}"]
  description = "${local.name} Record Files S3"
  tags {
    App = "${local.name}"
  }
}

module "assetsretrieval_sqs" {
  source  = "Aplyca/sqs/aws"
  version = "0.1.0"

  name    = "${local.name} AssetsRetrieval"
  description = "${local.name} AssetsRetrieval SQS"
  retention = 1209600
  wait_time = 20
  send_roles = ["${module.dap_importrecords_service.role}"]
  recieve_roles = ["${module.dap_assetsretrieval_service.role}"]
  max_recieve_count = 3
  tags {
    App = "${local.name}"
    Environment = "Prod"
  }
}

module "server-task_role" {
  source  = "modules/iam"

  name    = "${local.name} ECSTask Server"
  description = "${local.name} ECSTask Server"
  trusted = "ecs-tasks"
  tags {
    App = "${local.name}"
    Environment = "${local.env}"
  }
}

module "client-task_role" {
  source  = "modules/iam"

  name    = "${local.name} ECSTask Client"
  description = "${local.name} ECSTask Client"
  trusted = "ecs-tasks"
  tags {
    App = "${local.name}"
    Environment = "${local.env}"
  }
}