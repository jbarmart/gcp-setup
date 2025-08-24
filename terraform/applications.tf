resource "kubernetes_namespace" "applications_cluster1" {
  provider = kubernetes.cluster1
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_namespace" "applications_cluster2" {
  provider = kubernetes.cluster2
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_deployment" "nginx_cluster1" {
  provider = kubernetes.cluster1
  metadata {
    name      = "nginx-app"
    namespace = var.app_namespace
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:1.25"
          name  = "nginx"
          port {
            container_port = 80
          }
          resources {
            limits = {
              cpu    = "50m"
              memory = "64Mi"
            }
            requests = {
              cpu    = "25m"
              memory = "32Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.applications_cluster1]
}

resource "kubernetes_service" "nginx_service_cluster1" {
  provider = kubernetes.cluster1
  metadata {
    name      = "nginx-service"
    namespace = var.app_namespace
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.nginx_cluster1]
}

resource "kubernetes_deployment" "nginx_cluster2" {
  provider = kubernetes.cluster2
  metadata {
    name      = "nginx-app"
    namespace = var.app_namespace
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:1.25"
          name  = "nginx"
          port {
            container_port = 80
          }
          resources {
            limits = {
              cpu    = "50m"
              memory = "64Mi"
            }
            requests = {
              cpu    = "25m"
              memory = "32Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.applications_cluster2]
}

resource "kubernetes_service" "nginx_service_cluster2" {
  provider = kubernetes.cluster2
  metadata {
    name      = "nginx-service"
    namespace = var.app_namespace
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.nginx_cluster2]
}
