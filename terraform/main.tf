# GCP Setup - Main Terraform Configuration (PHASE 1: Infrastructure Only)
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # GCS backend for state storage
  backend "gcs" {
    bucket = "project-2-469918-terraform-state-bucket"
    prefix = "terraform/state"
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Data sources to get cluster credentials
data "google_container_cluster" "cluster1" {
  name     = var.cluster1_name
  location = var.zone
  depends_on = [google_container_cluster.cluster1]
}

data "google_container_cluster" "cluster2" {
  name     = var.cluster2_name
  location = var.zone
  depends_on = [google_container_cluster.cluster2]
}

# Kubernetes provider for cluster1
provider "kubernetes" {
  alias                  = "cluster1"
  host                   = "https://${data.google_container_cluster.cluster1.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster1.master_auth[0].cluster_ca_certificate)
}

# Kubernetes provider for cluster2
provider "kubernetes" {
  alias                  = "cluster2"
  host                   = "https://${data.google_container_cluster.cluster2.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster2.master_auth[0].cluster_ca_certificate)
}

# Data source for Google client config
data "google_client_config" "default" {}
