output "prod_cluster_id" {
  description = "Cluster ID"
  value       = module.gke["prod"].cluster_id
}
