terraform {
  backend "gcs" {
    bucket  = "clouddeploy-demo"
    prefix  = "canary"
  }
}