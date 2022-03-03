
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

provider "cloudflare" {
      alias = "dns"
      email = "${var.cloudflare_email}"
      api_key = "${var.cloudflare_key}"
  }


terraform {
  backend "s3" {
    #must be equal to the value defined in the state-bucket terraform (see readme for more info)
    bucket = "thompsonlabs-clappreg-service-tf-state" 
    #NOTE: this value should be set via the template script.
    key    = "thompsonlabs-clappreg-service/terraform.tfstate"
    #region = "eu-west-2"
    #must be equal to the value defined in the state-bucket terraform (see readme for more info)
    dynamodb_table = "clappreg-service-state-terraform-lock"
  }
}



module "service_ecs" {
  source                                           = "./modules/ecs"
  access_key                                       = "${var.access_key}"
  secret_key                                       = "${var.secret_key}"
  region                                           = "${var.region}"
  environment                                      = "${var.environment}"
  az_count                                         = "${var.az_count}"
  app_name                                         = "${var.app_name}"
  app_image                                        = "${var.app_image}"
  app_port                                         = "${var.app_port}"
  fargate_cpu                                      = "${var.fargate_cpu}"
  fargate_memory                                   = "${var.fargate_memory}"
  fargate_min_instances                            = "${var.fargate_min_instances}"
  fargate_max_instances                            = "${var.fargate_max_instances}"
  remote_network_state_bucket_name                 = "${var.remote_network_state_bucket_name}"
  service_discovery_registry_url                   = "${var.service_discovery_registry_url}"
  app_cluster_name                                 = "${var.app_cluster_name}"
  service_on_demand_base_instance_count            = "${var.service_on_demand_base_instance_count}"
  service_on_demand_instances_above_base_ratio     = "${var.service_on_demand_instances_above_base_ratio}"
  service_spot_instances_above_base_ratio          = "${var.service_spot_instances_above_base_ratio}"
  
  }



module "service_dns" {
  source                                           = "./modules/dns"
  environment                                      =  "${var.environment}"
  app_name                                         =  "${var.app_name}"
  domain_zone_id                                   =  "${var.domain_zone_id}"
  custom_subdomain                                 =  "${var.custom_subdomain}"
  target_domain                                    =  "${module.service_ecs.alb_hostname}"
  service_discovery_registry_url                   =  "${var.service_discovery_registry_url}"
  app_cluster_name                                 =  "${var.app_cluster_name}"                                    
  providers = {
    cloudflare = "${cloudflare.dns}"
  }

}  


output "service_dns_hostname" {

    value = "${module.service_dns}"
}
