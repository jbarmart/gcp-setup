# Terraform outputs for easy access to cluster information
output "cluster1_endpoint" {
  description = "GKE Cluster 1 endpoint"
  value       = google_container_cluster.cluster1.endpoint
  sensitive   = true
}

output "cluster2_endpoint" {
  description = "GKE Cluster 2 endpoint"
  value       = google_container_cluster.cluster2.endpoint
  sensitive   = true
}

output "cluster1_ca_certificate" {
  description = "GKE Cluster 1 CA certificate"
  value       = google_container_cluster.cluster1.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster2_ca_certificate" {
  description = "GKE Cluster 2 CA certificate"
  value       = google_container_cluster.cluster2.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "terraform_state_bucket" {
  description = "GCS bucket for Terraform state"
  value       = google_storage_bucket.terraform_state.name
}

# Application service outputs
output "nginx_service_cluster1_ip" {
  description = "External IP of nginx service on cluster 1"
  value       = kubernetes_service.nginx_service_cluster1.status.0.load_balancer.0.ingress.0.ip
}

output "nginx_service_cluster2_ip" {
  description = "External IP of nginx service on cluster 2"
  value       = kubernetes_service.nginx_service_cluster2.status.0.load_balancer.0.ingress.0.ip
}

# Application access information
output "nginx_access_info" {
  description = "Information to access nginx applications"
  value = {
    cluster1_url = "http://${kubernetes_service.nginx_service_cluster1.status.0.load_balancer.0.ingress.0.ip}"
    cluster2_url = "http://${kubernetes_service.nginx_service_cluster2.status.0.load_balancer.0.ingress.0.ip}"
  }
}
