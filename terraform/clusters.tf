# ============================================================================
# SECTION 1: GCP CLUSTERS AND INFRASTRUCTURE
# ============================================================================

# VPC Network for the clusters
resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
  description             = "VPC network for GKE clusters"
}

# Subnet for clusters
resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.64.0/22"  # Keep the original small range as-is
  }

  secondary_ip_range {
    range_name    = "pod-ranges-large"  # Keep the large range that already works
    ip_cidr_range = "10.100.0.0/16"   # 65,536 IPs - plenty of space
  }
}

# GKE Cluster 1
resource "google_container_cluster" "cluster1" {
  name     = var.cluster1_name
  location = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable network policy
  network_policy {
    enabled = true
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-ranges-large"  # Use the large range that already works
    services_secondary_range_name = "services-range"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
}

# Node pool for Cluster 1
resource "google_container_node_pool" "cluster1_nodes" {
  name       = "${var.cluster1_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.cluster1.name

  # Enable autoscaling instead of fixed node count
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  # Ignore changes to Google-managed configurations
  lifecycle {
    ignore_changes = [
      node_config[0].kubelet_config,
      node_config[0].resource_labels
    ]
  }

  node_config {
    machine_type = var.machine_type  # Use variable instead of hardcoded e2-small
    disk_size_gb = 50               # Increased from 30GB for better performance
    disk_type    = "pd-standard"  # Use standard disks instead of SSD

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      cluster = var.cluster1_name
      env     = "production"
    }

    resource_labels = {
      "goog-gke-node-pool-provisioning-model" = "on-demand"
    }

    tags = ["gke-node", var.cluster1_name]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# GKE Cluster 2
resource "google_container_cluster" "cluster2" {
  name     = var.cluster2_name
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled = true
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-ranges-large"  # Use the large range that already works
    services_secondary_range_name = "services-range"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
}

# Node pool for Cluster 2
resource "google_container_node_pool" "cluster2_nodes" {
  name       = "${var.cluster2_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.cluster2.name

  # Enable autoscaling instead of fixed node count
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  # Ignore changes to Google-managed configurations
  lifecycle {
    ignore_changes = [
      node_config[0].kubelet_config,
      node_config[0].resource_labels
    ]
  }

  node_config {
    machine_type = var.machine_type  # Use variable instead of hardcoded e2-small
    disk_size_gb = 50               # Increased from 30GB for better performance
    disk_type    = "pd-standard"

    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      cluster = var.cluster2_name
      env     = "production"
    }

    resource_labels = {
      "goog-gke-node-pool-provisioning-model" = "on-demand"
    }

    tags = ["gke-node", var.cluster2_name]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  description  = "Service account for GKE node pools"
}

# IAM bindings for the service account
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}
