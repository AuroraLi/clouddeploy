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

  name                 = "demoenv-${each.value.env}"
  random_project_id    = true
  folder_id  = var.folder 
  org_id = var.org 
  billing_account = var.billing
  activate_apis = [
      "compute.googleapis.com", "container.googleapis.com", "cloudbilling.googleapis.com","dns.googleapis.com","run.googleapis.com"
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
