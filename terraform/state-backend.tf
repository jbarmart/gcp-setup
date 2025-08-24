# ============================================================================
# SECTION 3: GCS BACKEND FOR TERRAFORM STATE
# ============================================================================

# GCS bucket for Terraform state storage
resource "google_storage_bucket" "terraform_state" {
  name          = var.terraform_state_bucket
  location      = var.region
  force_destroy = false

  # Enable versioning for state file history
  versioning {
    enabled = true
  }

  # Prevent accidental deletion
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  # Enable uniform bucket-level access
  uniform_bucket_level_access = true

  # Encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state_key.id
  }

  labels = {
    environment = "production"
    purpose     = "terraform-state"
  }
}

# KMS key ring for encryption
resource "google_kms_key_ring" "terraform_state" {
  name     = "terraform-state-keyring"
  location = var.region
}

# KMS crypto key for bucket encryption
resource "google_kms_crypto_key" "terraform_state_key" {
  name     = "terraform-state-key"
  key_ring = google_kms_key_ring.terraform_state.id

  lifecycle {
    prevent_destroy = true
  }
}
