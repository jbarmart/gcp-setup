# ============================================================================
# STREAMLINED DASHBOARDS AND ALERTING
# ============================================================================

# Custom Grafana dashboards for comprehensive pod monitoring
resource "kubernetes_config_map" "grafana_dashboards" {
  depends_on = [helm_release.kube_prometheus_stack]

  metadata {
    name      = "comprehensive-dashboards"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "pod-health-overview.json" = jsonencode({
      dashboard = {
        id       = null
        title    = "Pod Health Overview"
        tags     = ["kubernetes", "pods", "health"]
        timezone = "browser"
        refresh  = "30s"

        panels = [
          {
            id    = 1
            title = "Pod Status by Namespace"
            type  = "stat"
            targets = [
              {
                expr = "sum by (namespace, phase) (kube_pod_status_phase)"
                legendFormat = "{{namespace}} - {{phase}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 0, y = 0 }
          },
          {
            id    = 2
            title = "Pod Restart Count"
            type  = "graph"
            targets = [
              {
                expr = "sum by (namespace, pod) (kube_pod_container_status_restarts_total)"
                legendFormat = "{{namespace}}/{{pod}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 12, y = 0 }
          },
          {
            id    = 3
            title = "Memory Usage by Pod"
            type  = "graph"
            targets = [
              {
                expr = "sum by (namespace, pod) (container_memory_usage_bytes{container!=\"POD\",container!=\"\"})"
                legendFormat = "{{namespace}}/{{pod}}"
              }
            ]
            gridPos = { h = 8, w = 24, x = 0, y = 8 }
          },
          {
            id    = 4
            title = "CPU Usage by Pod"
            type  = "graph"
            targets = [
              {
                expr = "sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{container!=\"POD\",container!=\"\"}[5m]))"
                legendFormat = "{{namespace}}/{{pod}}"
              }
            ]
            gridPos = { h = 8, w = 24, x = 0, y = 16 }
          }
        ]
      }
    })

    "cluster-resource-utilization.json" = jsonencode({
      dashboard = {
        id       = null
        title    = "Cluster Resource Utilization"
        tags     = ["kubernetes", "cluster", "resources"]
        timezone = "browser"
        refresh  = "30s"

        panels = [
          {
            id    = 1
            title = "Node CPU Utilization"
            type  = "graph"
            targets = [
              {
                expr = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
                legendFormat = "{{instance}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 0, y = 0 }
          },
          {
            id    = 2
            title = "Node Memory Utilization"
            type  = "graph"
            targets = [
              {
                expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
                legendFormat = "{{instance}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 12, y = 0 }
          },
          {
            id    = 3
            title = "Pod Network I/O"
            type  = "graph"
            targets = [
              {
                expr = "sum by (namespace, pod) (rate(container_network_receive_bytes_total[5m]))"
                legendFormat = "{{namespace}}/{{pod}} - RX"
              },
              {
                expr = "sum by (namespace, pod) (rate(container_network_transmit_bytes_total[5m]))"
                legendFormat = "{{namespace}}/{{pod}} - TX"
              }
            ]
            gridPos = { h = 8, w = 24, x = 0, y = 8 }
          }
        ]
      }
    })

    "application-performance.json" = jsonencode({
      dashboard = {
        id       = null
        title    = "Application Performance Metrics"
        tags     = ["kubernetes", "applications", "performance"]
        timezone = "browser"
        refresh  = "30s"

        panels = [
          {
            id    = 1
            title = "HTTP Request Rate"
            type  = "graph"
            targets = [
              {
                expr = "sum by (namespace, pod) (rate(prometheus_http_requests_total[5m]))"
                legendFormat = "{{namespace}}/{{pod}}"
              }
            ]
            gridPos = { h = 8, w = 12, x = 0, y = 0 }
          },
          {
            id    = 2
            title = "Response Time Percentiles"
            type  = "graph"
            targets = [
              {
                expr = "histogram_quantile(0.95, sum by (namespace, pod, le) (rate(prometheus_http_request_duration_seconds_bucket[5m])))"
                legendFormat = "{{namespace}}/{{pod}} - 95th"
              },
              {
                expr = "histogram_quantile(0.50, sum by (namespace, pod, le) (rate(prometheus_http_request_duration_seconds_bucket[5m])))"
                legendFormat = "{{namespace}}/{{pod}} - 50th"
              }
            ]
            gridPos = { h = 8, w = 12, x = 12, y = 0 }
          },
          {
            id    = 3
            title = "Error Rate"
            type  = "graph"
            targets = [
              {
                expr = "sum by (namespace, pod) (rate(prometheus_http_requests_total{code=~\"5..\"}[5m])) / sum by (namespace, pod) (rate(prometheus_http_requests_total[5m])) * 100"
                legendFormat = "{{namespace}}/{{pod}}"
              }
            ]
            gridPos = { h = 8, w = 24, x = 0, y = 8 }
          }
        ]
      }
    })
  }
}

# ============================================================================
# ESSENTIAL ALERTING RULES (Using kubernetes_config_map instead of kubernetes_manifest)
# ============================================================================

# Prometheus rules as a ConfigMap (will be picked up by the operator)
resource "kubernetes_config_map" "prometheus_rules" {
  depends_on = [helm_release.kube_prometheus_stack]

  metadata {
    name      = "comprehensive-monitoring-rules"
    namespace = "monitoring"
    labels = {
      app = "comprehensive-monitoring"
      release = "kube-prometheus-stack"
      "prometheus" = "kube-prometheus-stack-prometheus"
      "role" = "alert-rules"
    }
  }

  data = {
    "pod-health.rules" = <<-EOF
      groups:
      - name: pod.health.rules
        rules:
        - alert: PodCrashLooping
          expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
            description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been restarting frequently"
        - alert: PodNotReady
          expr: kube_pod_status_ready{condition="false"} == 1
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} not ready"
            description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in not ready state for more than 10 minutes"
        - alert: PodHighMemoryUsage
          expr: (container_memory_usage_bytes{container!="POD",container!=""} / container_spec_memory_limit_bytes{container!="POD",container!=""}) > 0.9
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} high memory usage"
            description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} memory usage is above 90%"
      - name: cluster.health.rules
        rules:
        - alert: NodeNotReady
          expr: kube_node_status_condition{condition="Ready",status="true"} == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Node {{ $labels.node }} not ready"
            description: "Node {{ $labels.node }} has been not ready for more than 5 minutes"
        - alert: NodeHighMemoryUsage
          expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.85
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Node {{ $labels.instance }} high memory usage"
            description: "Node {{ $labels.instance }} memory usage is above 85%"
    EOF
  }
}

# ============================================================================
# SIMPLIFIED RBAC FOR MONITORING
# ============================================================================

resource "kubernetes_service_account" "monitoring_service_account" {
  depends_on = [kubernetes_namespace.monitoring]

  metadata {
    name      = "monitoring-service-account"
    namespace = "monitoring"
  }
}

resource "kubernetes_cluster_role" "monitoring_cluster_role" {
  metadata {
    name = "monitoring-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods", "ingresses", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status", "ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "monitoring_cluster_role_binding" {
  depends_on = [kubernetes_service_account.monitoring_service_account]

  metadata {
    name = "monitoring-cluster-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.monitoring_cluster_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.monitoring_service_account.metadata[0].name
    namespace = kubernetes_service_account.monitoring_service_account.metadata[0].namespace
  }
}

