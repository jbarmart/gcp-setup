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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
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

# Data source for Google client config
data "google_client_config" "default" {}

# Data sources to get cluster credentials - these will be available after clusters exist
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

# Default Kubernetes provider (points to cluster1) - used for monitoring stack
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.cluster1.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster1.master_auth[0].cluster_ca_certificate)
}

# Kubernetes provider for cluster1 (alias for existing applications)
provider "kubernetes" {
  alias                  = "cluster1"
  host                   = "https://${data.google_container_cluster.cluster1.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster1.master_auth[0].cluster_ca_certificate)
}

# Kubernetes provider for cluster2 (alias for existing applications)
provider "kubernetes" {
  alias                  = "cluster2"
  host                   = "https://${data.google_container_cluster.cluster2.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster2.master_auth[0].cluster_ca_certificate)
}

# Helm provider for installing monitoring stack on cluster1
provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.cluster1.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.cluster1.master_auth[0].cluster_ca_certificate)
  }
}
