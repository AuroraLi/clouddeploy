# Cloud Deploy demo

Main branch includes a setup for GKE, cloudrun branch includes a setup for Cloud run

## Infrastructure
use the terraform to create the infrastructure, including 4 GCP projects, Dev, Staging, Production, Deploy. In the first 3 projects, create a GKE cluster if using GKE, otherwise no infrastructure is needed for Cloud Run. Create a Cloud Deploy pipeline and artifact registry in the Deploy project. IAM is also configured. 

## Deploy using the pipeline
There is a `sampleapp` folder including a hello app and Kustomize manifest. You can set up a trigger to auto build and deploy the app. 