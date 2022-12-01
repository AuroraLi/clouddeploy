# clouddeploy
This repository is using Terraform to automatically create and configure Google Cloud Cloud Deploy for a pipeline to promote containerized application deployments from dev to staging to production. 

The Terraform will deploy 3 project for 3 environments, a GKE cluster in each project, and a DevOps project for Cloud Deploy pipeline. All IAM permissions are included as well. 
