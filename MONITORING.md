# 📊 GCP Multi-Cluster Monitoring Setup

## Overview

This monitoring solution provides comprehensive observability for your nginx applications running across two GKE clusters using Prometheus, Grafana, and AlertManager.

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    GCP PROJECT                                           │
│                                  project-2-469918                                       │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────────────────┐       ┌─────────────────────────────┐                │
│  │      GKE CLUSTER 1          │       │      GKE CLUSTER 2          │                │
│  │    app-cluster-1            │       │    app-cluster-2            │                │
│  │   us-central1-a             │       │   us-central1-a             │                │
│  ├─────────────────────────────┤       ├─────────────────────────────┤                │
│  │                             │       │                             │                │
│  │  📱 Applications Namespace  │       │  📱 Applications Namespace  │                │
│  │  ┌─────────────────────┐    │       │  ┌─────────────────────┐    │                │
│  │  │   nginx-app         │    │       │  │   nginx-app         │    │                │
│  │  │   (LoadBalancer)    │    │       │  │   (LoadBalancer)    │    │                │
│  │  │   34.121.230.139    │    │       │  │   34.44.230.72      │    │                │
│  │  └─────────────────────┘    │       │  └─────────────────────┘    │                │
│  │                             │       │                             │                │
│  │  📊 Monitoring Namespace    │       │  🔍 Metrics Collection      │                │
│  │  ┌─────────────────────┐    │       │  ┌─────────────────────┐    │                │
│  │  │  Prometheus Server  │    │       │  │   Node Exporter     │    │                │
│  │  │  (Metrics Storage)  │    │       │  │   (Node Metrics)    │    │                │
│  │  │                     │    │       │  │                     │    │                │
│  │  │  Grafana Dashboard  │◄───┼───────┤  │   Pod Metrics       │    │                │
│  │  │  34.171.68.101     │    │       │  │   Container Stats   │    │                │
│  │  │                     │    │       │  │                     │    │                │
│  │  │  AlertManager       │    │       │  └─────────────────────┘    │                │
│  │  │  104.154.23.253     │    │       │                             │                │
│  │  │                     │    │       │                             │                │
│  │  │  Node Exporter      │    │       │                             │                │
│  │  │  Kube State Metrics │    │       │                             │                │
│  │  └─────────────────────┘    │       │                             │                │
│  └─────────────────────────────┘       └─────────────────────────────┘                │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┤
│  │                          📈 MONITORING DATA FLOW                                   │
│  ├─────────────────────────────────────────────────────────────────────────────────────┤
│  │                                                                                     │
│  │  1. Node Exporters → Collect node-level metrics (CPU, Memory, Disk)               │
│  │  2. Kube State Metrics → Collect Kubernetes resource metrics                      │
│  │  3. Pod Metrics → Automatically scraped from all running pods                      │
│  │  4. Prometheus → Stores all metrics with 7-day retention                          │
│  │  5. Grafana → Visualizes metrics via custom dashboards                            │
│  │  6. AlertManager → Sends notifications for critical issues                         │
│  └─────────────────────────────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## 🎯 Monitoring Components

### Core Stack
- **Prometheus**: Time-series metrics database and monitoring system
- **Grafana**: Visualization and dashboarding platform
- **AlertManager**: Handles alerts sent by Prometheus server
- **Node Exporter**: Exposes hardware and OS metrics
- **Kube State Metrics**: Exposes Kubernetes cluster state metrics

### Custom Configuration
- **15-minute timeout** for reliable Helm deployments
- **7-day retention** for metrics storage (optimized for POC)
- **Automatic pod discovery** - monitors all pods without code changes
- **LoadBalancer services** for external access to dashboards

## 🌐 Access Points

### Grafana Dashboard (Primary UI)
```
URL: http://34.171.68.101
Username: admin
Password: monitoring123!
```

### AlertManager (Alert Management)
```
URL: http://104.154.23.253:9093
```

### Prometheus (Direct Metrics Access)
```bash
# Port forward to access Prometheus UI
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
# Then access: http://localhost:9090
```

## 📊 Available Dashboards

### 🎯 Primary Dashboard: "Nginx Applications - Multi-Cluster Health"
**Purpose**: Monitor your nginx applications across both clusters

**Key Metrics**:
- **Pod Status Overview**: Count of Running/Pending/Failed pods
- **Running Pods Count**: Total healthy pods (should be ≥2)
- **Recent Restarts**: Pod restart count in the last hour
- **Pod Details Table**: Detailed view of each pod's status and location
- **Memory Usage**: Real-time memory consumption per pod
- **CPU Usage**: Real-time CPU consumption per pod  
- **Network I/O**: Network traffic patterns per pod
- **Restart History**: Historical view of pod restarts

### 🔧 Additional Dashboards
- **Pod Health Overview**: General pod health across all namespaces
- **Cluster Resource Utilization**: Node-level resource usage
- **Application Performance Metrics**: HTTP request metrics (if available)

## 🚨 Alerting Rules

### Pod-Level Alerts
- **PodCrashLooping**: Pod restarts frequently (>0 restarts in 15min)
- **PodNotReady**: Pod not ready for >10 minutes
- **PodHighMemoryUsage**: Pod memory usage >90% of limit

### Cluster-Level Alerts
- **NodeNotReady**: Node unavailable for >5 minutes
- **NodeHighMemoryUsage**: Node memory usage >85%

## 📈 Metrics Being Collected

### Application Metrics (from `applications` namespace)
```prometheus
# Pod status and health
kube_pod_status_phase{namespace="applications"}
kube_pod_status_ready{namespace="applications"}
kube_pod_container_status_restarts_total{namespace="applications"}

# Resource usage
container_memory_usage_bytes{namespace="applications"}
container_cpu_usage_seconds_total{namespace="applications"}

# Network traffic
container_network_receive_bytes_total{namespace="applications"}
container_network_transmit_bytes_total{namespace="applications"}
```

### Node Metrics (from all nodes)
```prometheus
# CPU usage
node_cpu_seconds_total
# Memory usage  
node_memory_MemAvailable_bytes
node_memory_MemTotal_bytes
# Disk usage
node_filesystem_avail_bytes
```

## 🔍 Monitoring Your Applications

### 1. Check Application Health
1. Open Grafana: `http://34.171.68.101`
2. Navigate to "Nginx Applications - Multi-Cluster Health" dashboard
3. Verify:
   - ✅ **Running Pods Count** shows 2 or more
   - ✅ **Pod Status** shows all pods as "Running"
   - ✅ **Recent Restarts** shows 0 or low numbers

### 2. Monitor Resource Usage
- **Memory Usage panel**: Ensure pods stay within reasonable limits
- **CPU Usage panel**: Check for performance issues
- **Network I/O panel**: Monitor traffic patterns

### 3. Investigate Issues
- **Pod Details Table**: Identify which pod/node has problems
- **Restart History**: Check for recurring restart patterns
- Use AlertManager for proactive notifications

## 🚀 Deployment Commands

### Deploy Monitoring Stack
```bash
cd terraform/
terraform plan
terraform apply
```

### Verify Deployment
```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Check application pods  
kubectl get pods -n applications

# Port forward to access Prometheus locally
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
```

### Cleanup (if needed)
```bash
# Remove monitoring stack
helm uninstall kube-prometheus-stack -n monitoring

# Or destroy via Terraform
terraform destroy -target=helm_release.kube_prometheus_stack
```

## 🛠️ Customization

### Adding New Applications
The monitoring automatically discovers new pods in the `applications` namespace. No configuration changes needed.

### Modifying Retention
Edit `monitoring.tf`:
```hcl
retention = "30d"        # Change from 7d to 30d
retentionSize = "50GB"   # Increase storage
```

### Adding Custom Dashboards
Add new dashboard JSON to `dashboards.tf` in the `kubernetes_config_map` resource.

### Scaling Resources
Adjust resource requests/limits in `monitoring.tf`:
```hcl
resources = {
  requests = {
    cpu    = "500m"      # Increase CPU
    memory = "1Gi"       # Increase memory
  }
}
```

## 🔧 Troubleshooting

### Common Issues

#### Grafana Won't Load
```bash
# Check Grafana pod status
kubectl get pods -n monitoring | grep grafana

# Check service external IP
kubectl get svc -n monitoring | grep grafana

# Check logs
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana
```

#### No Metrics in Prometheus
```bash
# Port forward to Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring

# Visit http://localhost:9090 and check:
# - Status > Targets (should show green targets)
# - Status > Configuration (verify scrape configs)
```

#### Pods Not Showing in Dashboard
1. Verify pods are in `applications` namespace
2. Check Prometheus targets are discovering pods
3. Verify dashboard queries are correct

### Useful Debugging Commands
```bash
# Check all monitoring resources
kubectl get all -n monitoring

# Check Helm release status
helm list -n monitoring

# Check Prometheus configuration
kubectl get configmap -n monitoring kube-prometheus-stack-prometheus-rulefiles-0 -o yaml

# Test metric queries
curl http://localhost:9090/api/v1/query?query=kube_pod_status_phase
```

## 📋 Resource Requirements

### Per Cluster
- **Prometheus**: 1 CPU, 1GB RAM, 10GB storage
- **Grafana**: 0.5 CPU, 512MB RAM, 2GB storage  
- **AlertManager**: 0.05 CPU, 128MB RAM, 1GB storage
- **Node Exporters**: 0.1 CPU, 128MB RAM per node
- **Total**: ~2 CPU, 2GB RAM, 13GB storage per cluster

### Network
- Grafana LoadBalancer: 1 external IP
- AlertManager LoadBalancer: 1 external IP
- Internal cluster communication on standard ports

---

## 📞 Support

For issues or questions about this monitoring setup:

1. **Check logs**: Use `kubectl logs` commands above
2. **Verify configuration**: Compare with working examples in `terraform/`
3. **Test connectivity**: Ensure external IPs are accessible
4. **Monitor resources**: Check if pods have sufficient CPU/memory

**Key Files**:
- `terraform/monitoring.tf` - Main Helm configuration
- `terraform/dashboards.tf` - Custom dashboard definitions
- `terraform/applications.tf` - Application deployments being monitored
