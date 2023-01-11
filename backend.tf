terraform {
  backend "gcs" {
    bucket  = "clouddeploy-demo"
    prefix  = "terraform/state"
  }
}