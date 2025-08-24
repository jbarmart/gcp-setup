variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "project-2-469918"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster1_name" {
  description = "Name of the first GKE cluster"
  type        = string
  default     = "app-cluster-1"
}

variable "cluster2_name" {
  description = "Name of the second GKE cluster"
  type        = string
  default     = "app-cluster-2"
}

variable "node_count" {
  description = "Number of nodes in each cluster"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "terraform_state_bucket" {
  description = "GCS bucket name for Terraform state"
  type        = string
}

variable "app_namespace" {
  description = "Kubernetes namespace for applications"
  type        = string
  default     = "applications"
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "domain_name" {
  description = "Domain name for monitoring UIs (Grafana, Prometheus, etc.)"
  type        = string
  default     = "monitoring.example.com"
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "admin@example.com"
}
