provider "google" {
#   project     = var.gcp_project_id
  region      = var.gcp_region
}

locals {
  envs = {
    for x in var.envs :
    "${x.env}" => x
  }
}
module "project-factory" {
    for_each = local.envs
  source  = "terraform-google-modules/project-factory/google"
#   version = "~> 10.1"

  name                 = "nats-${each.value.env}"
  random_project_id    = true
  folder_id  = 339514276699
  org_id = 75928084081
  billing_account = var.billing
  activate_apis = [
      "compute.googleapis.com", "container.googleapis.com", "cloudbilling.googleapis.com","dns.googleapis.com"
  ]
  default_service_account = "keep"
}

# resource "google_pubsub_topic" "example" {
#   name = "example-topic"
#   project = google_project.publisher.id
#   labels = {
#     foo = "bar"
#   }

#   message_retention_duration = "86600s"
# }

module "vpc" {
    for_each = local.envs
    source  = "terraform-google-modules/network/google//modules/vpc"
    
    project_id   = module.project-factory["${each.value.env}"].project_id
    network_name = "vpc-01"

    shared_vpc_host = false

}

module "subnets" {
    for_each = local.envs
    source  = "terraform-google-modules/network/google//modules/subnets"
    # version = "~> 2.0.0"

    project_id   = module.project-factory["${each.value.env}"].project_id
    network_name = module.vpc["${each.value.env}"].network_name

    subnets = [
        {
            subnet_name           = "subnet"
            subnet_ip             = "10.10.0.0/24"
            subnet_region         = var.gcp_region
            # subnet_private_access = "true"
        },
    ]

    secondary_ranges = {
        subnet = [
            {
                range_name    = "pod"
                ip_cidr_range = "10.0.0.0/16"
            },
            {
                range_name    = "svc"
                ip_cidr_range = "10.1.0.0/16"
            },
        ]
    }
    }

data "google_client_config" "default" {}

# provider "kubernetes" {
#     for_each = local.envs
#     # alias = each.value.env
#   host                   = "https://${module.gke["${each.value.env}"].endpoint}"
#   token                  = data.google_client_config.default.access_token
#   cluster_ca_certificate = base64decode(module.gke["${each.value.env}"].ca_certificate)
# }

module "gke" {
    for_each = local.envs
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-public-cluster"
  project_id                 = module.project-factory["${each.value.env}"].project_id
  name                       = "${each.value.env}"
  region                     = var.gcp_region
  zones                      = ["${var.gcp_region}-a", "${var.gcp_region}-b", "${var.gcp_region}-f"]
  network                    = module.vpc["${each.value.env}"].network_name
  subnetwork                 = "subnet"
  ip_range_pods              = "pod"
  ip_range_services          = "svc"
  horizontal_pod_autoscaling = true
  enable_vertical_pod_autoscaling   = true
  create_service_account     = false
  service_account = module.project-factory["${each.value.env}"].service_account_name
#   filestore_csi_driver       = false
#   enable_private_endpoint    = true
#   enable_private_nodes       = true
#   master_ipv4_cidr_block     = "10.100.0.0/28"
#   master_authorized_networks = [{cidr_block="0.0.0.0/0",display_name="all"}]

 
 
}

# resource "google_project_iam_member" "gke-read" {
#     for_each = local.envs
#   project = module.project-factory["${each.value.env}"].project_id
#   role    = "roles/editor"
#   member  = module.gke["${each.value.env}"].service_account
# }

resource "google_compute_firewall" "gke-rules" {
  for_each = local.envs
  project = module.project-factory["${each.value.env}"].project_id
  name        = "googleapi"
  network     = module.vpc["${each.value.env}"].network_name
  description = "Creates firewall rule for egress"

  allow {
    protocol  = "tcp"
    ports = ["80","443"]
  }
  direction = "EGRESS"
  
  
}