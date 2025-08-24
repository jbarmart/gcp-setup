# ============================================================================
# STREAMLINED MONITORING AND OBSERVABILITY SOLUTION
# ============================================================================
# Focused on core metrics collection and visualization without requiring
# application team changes

# ============================================================================
# PROMETHEUS OPERATOR AND MONITORING STACK
# ============================================================================

# Create a dedicated namespace for monitoring infrastructure
resource "kubernetes_namespace" "monitoring" {
  depends_on = [google_container_cluster.cluster1, google_container_cluster.cluster2]

  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Install Prometheus Operator using Helm
resource "helm_release" "kube_prometheus_stack" {
  depends_on = [kubernetes_namespace.monitoring]

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "55.5.0"

  # Timeout and wait configurations to prevent deployment issues
  timeout         = 900  # 15 minutes timeout
  wait            = true
  wait_for_jobs   = true
  create_namespace = false  # We create the namespace separately

  # Custom values to configure the monitoring stack
  values = [
    yamlencode({
      # Global configuration
      global = {
        resolve_timeout = "5m"
      }

      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          # Resource requests and limits - optimized for e2-medium nodes
          resources = {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }

          # Storage configuration
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"  # Reduced for POC
                  }
                }
                storageClassName = "standard-rwo"
              }
            }
          }

          # Retention policy - shorter for POC
          retention = "7d"
          retentionSize = "8GB"

          # Service discovery configuration to monitor all pods automatically
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues = false
          ruleSelectorNilUsesHelmValues = false

          # Comprehensive pod monitoring - works without app team changes
          additionalScrapeConfigs = [
            {
              job_name = "kubernetes-pods-comprehensive"
              honor_labels = true
              kubernetes_sd_configs = [
                {
                  role = "pod"
                }
              ]
              relabel_configs = [
                # Monitor all pods, not just those with prometheus annotations
                {
                  source_labels = ["__meta_kubernetes_pod_phase"]
                  action = "keep"
                  regex = "Running"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_container_port_name"]
                  action = "keep"
                  regex = ".*"
                },
                {
                  action = "labelmap"
                  regex = "__meta_kubernetes_pod_label_(.+)"
                },
                {
                  source_labels = ["__meta_kubernetes_namespace"]
                  action = "replace"
                  target_label = "kubernetes_namespace"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_name"]
                  action = "replace"
                  target_label = "kubernetes_pod_name"
                },
                {
                  source_labels = ["__meta_kubernetes_pod_container_name"]
                  action = "replace"
                  target_label = "kubernetes_container_name"
                }
              ]
              # Try common metrics endpoints
              metrics_path = "/metrics"
              scrape_interval = "30s"
              scrape_timeout = "10s"
            }
          ]
        }

        # Service configuration for external access
        service = {
          type = "ClusterIP"
        }
      }

      # Grafana configuration - the main UI for your POC
      grafana = {
        # Enable admin user with simple password for POC
        adminPassword = "monitoring123!"

        # Resource configuration - optimized for demo
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }

        # Persistence for dashboards and settings
        persistence = {
          enabled = true
          size = "2Gi"
          storageClassName = "standard-rwo"
        }

        # Service configuration
        service = {
          type = "LoadBalancer"  # Easy external access for POC
        }

        # Enable plugins for better visualization
        plugins = [
          "grafana-piechart-panel",
          "grafana-worldmap-panel"
        ]

        # Use sidecar to manage datasources automatically
        sidecar = {
          datasources = {
            enabled = true
            defaultDatasourceEnabled = true
            # Let the helm chart handle datasource creation automatically
          }
        }
      }

      # Node Exporter - essential for node-level metrics
      nodeExporter = {
        enabled = true
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }

      # kube-state-metrics - essential for Kubernetes resource metrics
      kubeStateMetrics = {
        enabled = true
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }

      # Alertmanager - for proactive monitoring
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          resources = {
            requests = {
              cpu    = "25m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "50m"
              memory = "128Mi"
            }
          }
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "1Gi"
                  }
                }
                storageClassName = "standard-rwo"
              }
            }
          }
        }
        service = {
          type = "LoadBalancer"  # Easy access for POC
        }
      }
    })
  ]

  # Wait for the monitoring namespace to be ready
}
