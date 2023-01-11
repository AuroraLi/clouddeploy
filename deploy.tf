locals {
    deploy-targets = {
    for x in var.envs :
    "${x.env}" => merge(x,{project_id="${module.project-factory["${x.env}"].project_id}"},{cluster="${module.gke["${x.env}"].name}"})
    
  }
}

module "deploy-project" {
  source  = "terraform-google-modules/project-factory/google"
#   version = "~> 10.1"

  name                 = "nats-deploy"
  random_project_id    = true
  folder_id  = 339514276699
  org_id = 75928084081
  billing_account = var.billing
  activate_apis = [
      "artifactregistry.googleapis.com","clouddeploy.googleapis.com","cloudbuild.googleapis.com","storage-component.googleapis.com","container.googleapis.com"
  ]
  default_service_account = "keep"
}


resource "local_file" "deploy_config" {
  filename = "${path.module}/clouddeploy.yaml"
  content  = templatefile("clouddeploy.yaml.tftpl",{region="${var.gcp_region}",envs="${local.deploy-targets}"})
}

module "gcloud" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 2.0"

  platform = "linux"
  skip_download = true
#   additional_components = ["kubectl", "beta"]

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "deploy apply --file=${local_file.deploy_config.filename} --region=${var.gcp_region} --project=${module.deploy-project.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "deploy --quiet delivery-pipelines delete deploy-pipeline"
  depends_on = [
    # resource.local_file.deploy_config
  ]
}

resource "google_project_iam_member" "deploy_sa" {
    for_each = local.envs
  project = module.project-factory["${each.value.env}"].project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${module.deploy-project.project_number}-compute@developer.gserviceaccount.com"
}


resource "google_project_iam_member" "github_sa" {
  project = module.deploy-project.project_id
  role    = "roles/clouddeploy.releaser"
  member  = "serviceAccount:${var.cicdsa}"
  }
# resource "google_project_iam_member" "build_log" {
#     for_each = local.envs
#   project = module.project-factory["${each.value.env}"].project_id
#   role    = "roles/logging.logWriter"
#   member  = "serviceAccount:${module.project-factory["${each.value.env}"].project_number}@cloudbuild.gserviceaccount.com"
# }

resource "google_artifact_registry_repository" "image-repo" {
  location      = var.gcp_region
  project = module.deploy-project.project_id
  repository_id = "video-process"
  description   = "example docker repository"
  format        = "DOCKER"
}

resource "google_project_iam_member" "ar_sa" {
  project = module.deploy-project.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.cicdsa}"
  }
resource "google_project_iam_member" "gcs_sa" {
  project = module.deploy-project.project_id
  role    = "roles/clouddeploy.serviceAgent"
  member  = "serviceAccount:${var.cicdsa}"
  }
resource "google_project_iam_member" "cloudbuild_sa" {
  project = module.deploy-project.project_id
  role    = "roles/cloudbuild.serviceAgent"
  member  = "serviceAccount:${var.cicdsa}"
  }
resource "google_project_iam_member" "logs_sa" {
  project = module.deploy-project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${module.deploy-project.project_number}-compute@developer.gserviceaccount.com"
  }

resource "google_project_iam_member" "logging_sa" {
  project = module.deploy-project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${module.deploy-project.project_number}@cloudbuild.gserviceaccount.com"
  }


resource "google_project_iam_member" "read_sa" {
  project = module.deploy-project.project_id
  role    = "roles/clouddeploy.jobRunner"
  member  = "serviceAccount:${module.deploy-project.project_number}-compute@developer.gserviceaccount.com"
  }


resource "google_project_iam_member" "ar_read_sa" {
    for_each = local.envs
  project = module.deploy-project.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${module.project-factory[each.value.env].project_number}-compute@developer.gserviceaccount.com"
  }