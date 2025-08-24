# GCP Multi-Cluster Setup with Terraform and Helm

This repository provides a complete, production-ready setup for deploying applications across multiple Google Cloud Platform (GCP) clusters with comprehensive monitoring, using Terraform for infrastructure management and Helm for application deployment.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    Google Cloud Platform                                         │
│                                         project-2-469918                                        │                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                                VPC Network (10.0.0.0/16)                                │   │
│  │                                   gke-vpc                                                │   │
│  │                                                                                         │   │
│  │  ┌──────────────────────────────────┐    ┌──────────────────────────────────┐        │   │
│  │  │         GKE Cluster 1            │    │         GKE Cluster 2            │        │   │
│  │  │      (app-cluster-1)             │    │      (app-cluster-2)             │        │   │
│  │  │     3 x e2-medium nodes          │    │     3 x e2-medium nodes          │        │   │
│  │  │                                  │    │                                  │        │   │
│  │  │  ┌─────────────────────────────┐ │    │  ┌─────────────────────────────┐ │        │   │
│  │  │  │    Monitoring Namespace     │ │    │  │    Monitoring Namespace     │ │        │   │
│  │  │  │      (monitoring.tf         │ │    │  │      (monitoring.tf         │ │        │   │
│  │  │  │       DISABLED)             │ │    │  │       DISABLED)             │ │        │   │
│  │  │  │                             │ │    │  │                             │ │        │   │
│  │  │  │  ⏸️  Prometheus: 9090       │ │    │  │  ⏸️  Prometheus: 9090       │ │        │   │
│  │  │  │  ⏸️  Grafana: 3000          │ │    │  │  ⏸️  Grafana: 3000          │ │        │   │
│  │  │  │  ⏸️  AlertManager: 9093     │ │    │  │  ⏸️  AlertManager: 9093     │ │        │   │
│  │  │  │  ⏸️  Node Exporter: 9100    │ │    │  │  ⏸️  Node Exporter: 9100    │ │        │   │
│  │  │  └─────────────────────────────┘ │    │  └─────────────────────────────┘ │        │   │
│  │  │                                  │    │                                  │        │   │
│  │  │  ┌─────────────────────────────┐ │    │  ┌─────────────────────────────┐ │        │   │
│  │  │  │   Applications Namespace    │ │    │  │   Applications Namespace    │ │        │   │
│  │  │  │     (applications.tf        │ │    │  │     (applications.tf        │ │        │   │
│  │  │  │      DISABLED)              │ │    │  │      DISABLED)              │ │        │   │
│  │  │  │                             │ │    │  │                             │ │        │   │
│  │  │  │  ⏸️  Web App: 80 (LB)       │ │    │  │  ⏸️  Web App: 80 (LB)       │ │        │   │
│  │  │  │  ⏸️  API Service: 8080      │ │    │  │  ⏸️  Background Worker      │ │        │   │
│  │  │  │  ⏸️  2-3 replicas each      │ │    │  │  ⏸️  1 replica              │ │        │   │
│  │  │  └─────────────────────────────┘ │    │  └─────────────────────────────┘ │        │   │
│  │  │                                  │    │                                  │        │   │
│  │  │  Service Account:                │    │  Service Account:                │        │   │
│  │  │  gke-service-account            │    │  gke-service-account            │        │   │
│  │  │  (Workload Identity)            │    │  (Workload Identity)            │        │   │
│  │  └──────────────────────────────────┘    └──────────────────────────────────┘        │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                           Terraform State Management                                │   │
│  │                                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                   GCS Bucket (Encrypted with KMS)                          │   │   │
│  │  │              project-2-469918-terraform-state-bucket                       │   │   │
│  │  │                                                                             │   │   │
│  │  │  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐ │   │   │
│  │  │  │   terraform.tfstate │  │  terraform-state-   │  │    Versioning       │ │   │   │
│  │  │  │   (14 Resources)    │  │      keyring        │  │    Enabled          │ │   │   │
│  │  │  │                     │  │  KMS Encryption     │  │    30-day lifecycle │ │   │   │
│  │  │  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

                          ┌─────────────────────────────────┐
                          │        Your Authentication      │
                          │   jsbarasch@gmail.com (Owner)  │
                          │   gcloud auth application-     │
                          │        default login           │
                          └─────────────────────────────────┘
                                         │
                               ┌─────────▼─────────┐
                               │   Terraform       │
                               │   Management      │
                               │   (No JSON keys)  │
                               └───────────────────┘

```

## 🎯 Architecture Components

### **Phase 1: Infrastructure Foundation (Currently Deployed)**
- **VPC Network**: `gke-vpc` with subnet `10.0.0.0/16` 
- **Secondary IP Ranges**: Pod ranges (`192.168.64.0/22`) and service ranges (`192.168.1.0/24`)
- **2 GKE Clusters**: `app-cluster-1` and `app-cluster-2` (3 x e2-medium nodes each)
- **Service Account**: `gke-service-account` for node pools with Workload Identity
- **State Management**: Encrypted GCS bucket with KMS for Terraform state

### **Phase 2: Monitoring Stack (Ready to Enable)** 
- **Prometheus Server**: Port `9090`, 50Gi storage, 15-day retention
- **Grafana Dashboard**: Port `3000` (LoadBalancer), pre-configured dashboards
- **AlertManager**: Port `9093`, 10Gi storage
- **Node Exporter**: Port `9100` (DaemonSet on all nodes)
- **Blackbox Exporter**: External endpoint monitoring
- **Agentless Discovery**: No pod configuration required

### **Phase 3: Sample Applications (Ready to Enable)**
- **Cluster 1**: Web App (nginx:80) + API Service (httpd:8080)
- **Cluster 2**: Web App (nginx:80) + Background Worker (busybox)
- **Auto-scaling**: HPA enabled, resource limits configured
- **Load Balancing**: External LoadBalancers for web apps

## 🚀 Current Deployment Status

| Component | Status | Resources | Location |
|-----------|--------|-----------|----------|
| **VPC Network** | ⏳ Ready to Deploy | 1 VPC + 1 Subnet | us-central1 |
| **GKE Clusters** | ⏳ Ready to Deploy | 2 Clusters + 2 Node Pools | us-central1-a |
| **Service Account** | ⏳ Ready to Deploy | 1 GKE Service Account | project-2-469918 |
| **State Backend** | ⏳ Ready to Deploy | GCS + KMS Resources | us-central1 |
| **Monitoring** | 🔄 Disabled | monitoring.tf.disabled | Will enable after clusters |
| **Applications** | 🔄 Disabled | applications.tf.disabled | Will enable after clusters |

## 📦 **GCP Resources Ready to Deploy**

### **Infrastructure Resources (14 Total)**

#### **Networking**
- **VPC Network**: `gke-vpc` with custom subnetting
- **Subnet**: `gke-subnet` (10.0.0.0/16) with secondary ranges
- **Firewall**: Automatic GKE firewall rules

#### **GKE Clusters**
- **Cluster 1**: `app-cluster-1` in `us-central1-a`
  - Node Pool: 3 x e2-medium nodes
  - Workload Identity enabled
  - Network policies enabled
  - Logging and monitoring enabled
- **Cluster 2**: `app-cluster-2` in `us-central1-a`
  - Node Pool: 3 x e2-medium nodes  
  - Same configuration as Cluster 1

#### **Service Account & IAM**
- **GKE Service Account**: `gke-service-account@project-2-469918.iam.gserviceaccount.com`
- **IAM Roles Granted**:
  - `roles/logging.logWriter` - Send logs to Cloud Logging
  - `roles/monitoring.metricWriter` - Send metrics to Cloud Monitoring
  - `roles/monitoring.viewer` - Read monitoring data
  - `roles/stackdriver.resourceMetadata.writer` - Write resource metadata

#### **State Management**
- **GCS Bucket**: `project-2-469918-terraform-state-bucket`
  - Location: us-central1
  - KMS encryption with customer-managed key
  - Versioning enabled, 30-day lifecycle policy
- **KMS Key Ring**: `terraform-state-keyring` 
- **KMS Crypto Key**: `terraform-state-key`

### **Authentication Setup**

**Your Account (Terraform Management):**
- **User**: `jsbarasch@gmail.com` 
- **Role**: Owner
- **Authentication**: `gcloud auth application-default login`
- **No JSON keys required**

**GKE Service Account (Node Authentication):**
- **Account**: `gke-service-account`
- **Authentication**: Automatic via Workload Identity
- **No JSON keys required**

## 🛠️ Quick Start

### Prerequisites
- ✅ Google Cloud SDK (installed and configured)
- ✅ Terraform >= 1.0 (installed)
- ✅ Project: `project-2-469918` (active)
- ✅ APIs: Cloud KMS, Container, Compute, Storage (enabled)
- ✅ Authentication: Application Default Credentials (configured)

### Phase 1: Deploy Infrastructure Foundation

```bash
# Navigate to terraform directory
cd /Users/jacobbarasch/PycharmProjects/gcp-setup/terraform

# Review what will be deployed
terraform plan

# Deploy the foundation (GKE clusters + networking + state management)
terraform apply
```

**This will create:**
- 2 GKE clusters with 6 total nodes
- VPC networking with proper subnetting  
- GKE service account with required permissions
- Encrypted state management in GCS

### Phase 2: Enable Monitoring (After Phase 1)

```bash
# Enable monitoring stack
mv monitoring.tf.disabled monitoring.tf

# Add Kubernetes and Helm providers back to main.tf
# Update main.tf with cluster data sources and providers

# Deploy monitoring
terraform apply
```

### Phase 3: Enable Applications (After Phase 2)

```bash
# Enable applications
mv applications.tf.disabled applications.tf

# Deploy sample applications
terraform apply
```

## 📁 Project Structure

```
├── README.md                    # This documentation
└── terraform/
    ├── main.tf                  # Core Terraform config (Google provider only)
    ├── variables.tf             # Input variables
    ├── terraform.tfvars         # Your configuration values
    ├── clusters.tf              # GKE clusters and networking
    ├── state-backend.tf         # GCS bucket + KMS encryption  
    ├── outputs.tf              # Terraform outputs
    ├── monitoring.tf.disabled   # 🔄 Prometheus + Grafana (Phase 2)
    ├── applications.tf.disabled # 🔄 Sample apps (Phase 3)
    └── terraform.tfvars.example # Configuration template
```

## 🔧 Configuration Files

**Current terraform.tfvars:**
```hcl
project_id = "project-2-469918"
region     = "us-central1"  
zone       = "us-central1-a"

cluster1_name = "app-cluster-1"
cluster2_name = "app-cluster-2"
node_count    = 3
machine_type  = "e2-medium"

terraform_state_bucket = "project-2-469918-terraform-state-bucket"

app_namespace        = "applications"
monitoring_namespace = "monitoring"
```

## 💰 Cost Estimation

**Phase 1 Monthly Costs:**
- **GKE Clusters**: ~$150/month (2 clusters × 3 nodes × e2-medium)
- **VPC Networking**: ~$5/month
- **State Management**: ~$0.11/month (GCS + KMS)
- **Total Phase 1**: ~$155/month

**Phase 2 Additional Costs:**
- **Monitoring Stack**: ~$20/month (Prometheus storage + Grafana)

**Phase 3 Additional Costs:**
- **LoadBalancers**: ~$20/month (2 external LoadBalancers)

## 🔒 Security Features

- **Workload Identity**: Secure pod-to-GCP service authentication
- **Network Policies**: Pod-to-pod traffic control enabled
- **KMS Encryption**: State files encrypted with customer-managed keys
- **Private Subnetting**: Isolated application networks
- **Service Account Isolation**: Minimal required permissions
- **No JSON Keys**: Authentication via Google's internal services

## 🧹 Cleanup

```bash
cd /Users/jacobbarasch/PycharmProjects/gcp-setup/terraform
terraform destroy
```

**Note**: KMS keys cannot be immediately deleted due to security policies. They will be scheduled for destruction.

## 🚨 Production Considerations

### Before Going to Production:
- [ ] Enable GKE private clusters
- [ ] Configure backup policies for persistent volumes  
- [ ] Set up log aggregation and retention policies
- [ ] Implement network security policies
- [ ] Configure SSL certificates for HTTPS
- [ ] Set up proper alerting rules in AlertManager
- [ ] Review and adjust resource quotas
- [ ] Enable binary authorization for container security

### Monitoring Ready Features:
- ✅ **Agentless Discovery**: No application code changes required
- ✅ **Pre-configured Dashboards**: Kubernetes monitoring out of the box
- ✅ **Automatic Scaling**: HPA and cluster autoscaling enabled
- ✅ **Health Checks**: Blackbox monitoring for external endpoints

## 🧪 Testing Your Deployment

### Automated Testing Script

This repository includes a comprehensive testing script (`test-nginx-apps.sh`) that validates your GKE cluster deployments and nginx applications. The script performs multiple types of tests to ensure your infrastructure is working correctly.

### Running the Tests

```bash
# Make the script executable and run it
chmod +x test-nginx-apps.sh
./test-nginx-apps.sh
```

### What the Tests Cover

The testing script performs 5 comprehensive test suites:

1. **Basic Connectivity Test**: Verifies HTTP response codes and response times
2. **Content Verification**: Confirms proper HTML content is being served
3. **Load Testing**: Tests with 10 concurrent requests to verify performance
4. **Kubernetes Resource Status**: Checks pod health, services, and LoadBalancer IPs
5. **Pod Health Check**: Validates individual pod responses

### Example Test Output

When you run the test script, you should see output similar to this:

```
=== Testing nginx applications in GKE clusters ===

Cluster 1 IP: 34.121.230.139
Cluster 2 IP: 34.44.230.72

=== Test 1: Basic Connectivity ===
Testing Cluster 1...
Status: 200, Time: 0.130536s, Size: 615 bytes
Testing Cluster 2...
Status: 200, Time: 0.268854s, Size: 615 bytes

=== Test 2: Content Verification ===
Cluster 1 response (first 3 lines):
<!DOCTYPE html>
<html>
<head>

Cluster 2 response (first 3 lines):
<!DOCTYPE html>
<html>
<head>

=== Test 3: Load Testing (10 requests each) ===
Testing Cluster 1 load handling...
Request 1: 0.194449s
Request 2: 0.108168s
Request 3: 0.119420s
Request 4: 0.233658s
Request 5: 0.106518s
Request 6: 0.135449s
Request 7: 0.119187s
Request 8: 0.183182s
Request 9: 0.105651s
Request 10: 0.194052s

Testing Cluster 2 load handling...
Request 1: 0.153047s
Request 2: 0.106215s
Request 3: 0.107971s
Request 4: 0.106692s
Request 5: 0.180819s
Request 6: 0.105511s
Request 7: 0.148358s
Request 8: 0.181506s
Request 9: 0.145330s
Request 10: 0.118951s

=== Test 4: Kubernetes Resource Status ===
Cluster 1 pods:
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-54c6c77df5-8nwwl   1/1     Running   0          48m
nginx-app-54c6c77df5-m9jv6   1/1     Running   0          48m

Cluster 2 pods:
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-54c6c77df5-84qwb   1/1     Running   0          48m
nginx-app-54c6c77df5-sgbw4   1/1     Running   0          48m

Cluster 1 service:
NAME            TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
nginx-service   LoadBalancer   192.168.1.59   34.121.230.139   80:30110/TCP   45m

Cluster 2 service:
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
nginx-service   LoadBalancer   192.168.1.168   34.44.230.72   80:32034/TCP   46m

=== Test 5: Pod Health Check ===
Testing individual pods in Cluster 1:
<!DOCTYPE html>

Testing individual pods in Cluster 2:
<!DOCTYPE html>

=== All tests completed! ===
```

### Understanding Test Results

**✅ Successful Test Indicators:**
- HTTP Status: `200` (OK responses)
- Response Times: Under 0.3 seconds (good performance)
- Pod Status: `Running` with `READY 1/1`
- Services: External IPs assigned to LoadBalancers
- Content: Valid HTML with `<!DOCTYPE html>` declarations
- Restarts: `0` (stable pods with no crashes)

**🔍 What Each Test Validates:**
- **Test 1**: Confirms both clusters are accessible from the internet
- **Test 2**: Verifies nginx is serving proper web content
- **Test 3**: Ensures clusters can handle concurrent load
- **Test 4**: Validates Kubernetes resources are healthy
- **Test 5**: Confirms individual pod health and connectivity

### Manual Testing Commands

You can also test individual components manually:

```bash
# Get cluster external IPs
kubectl get services -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-1
kubectl get services -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-2

# Test direct connectivity
curl -I http://YOUR_CLUSTER1_IP
curl -I http://YOUR_CLUSTER2_IP

# Check pod status
kubectl get pods -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-1
kubectl get pods -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-2
```

### Troubleshooting Failed Tests

If tests fail, check:
1. **LoadBalancer Services**: Ensure external IPs are assigned (may take 2-3 minutes)
2. **Pod Status**: Verify pods are in `Running` state
3. **Network Connectivity**: Check VPC firewall rules
4. **Application Deployment**: Confirm nginx applications are properly deployed
