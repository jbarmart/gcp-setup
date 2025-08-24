# Example terraform.tfvars file
# Copy this to terraform.tfvars and fill in your values

project_id = "project-2-469918"
region     = "us-central1"
zone       = "us-central1-a"

cluster1_name = "app-cluster-1"
cluster2_name = "app-cluster-2"
node_count    = 1  # Reduced to 1 node per cluster - sufficient for nginx app
machine_type  = "e2-medium"

terraform_state_bucket = "project-2-469918-terraform-state-bucket"

app_namespace        = "applications"
monitoring_namespace = "monitoring"
