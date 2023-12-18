

locals {
  grafana-name = "self-monitor-cluster-grafana"
}

resource "kubernetes_deployment" "self-monitor-cluster-grafana" {

  metadata {
    namespace = var.configs.namespace
    name      = local.grafana-name
    labels = {
      kubernetes_deployment_name = local.grafana-name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        kubernetes_deployment_name = local.grafana-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.grafana-name
        }
      }

      spec {
        container {
          image             = "grafana/grafana:10.2.2"
          image_pull_policy = "IfNotPresent"
          name              = local.grafana-name

          resources {
            limits = {
              cpu    = "1" #todo
              memory = "1Gi"
            }
            requests = {
              cpu    = "1"
              memory = "1Gi"
            }
          }

          port {
            container_port = 3000
          }

          volume_mount {
            name       = "self-monitor-cluster-pvc"
            mount_path = "/vm-data/self-moniotor-cluster/grafana/"
          }

          env {
            name = "CONTAINER_NAME"

            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "CONTAINER_IP"

            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name  = "GOMAXPROCS"
            value = "1"
          }

          # env {
          #   name  = "GF_SECURITY_ADMIN_USER"
          #   value = "admin"
          # }
          # env {
          #   name  = "GF_SECURITY_ADMIN_PASSWORD"
          #   value = "admin"  #todo:
          # }
          env {
            name  = "GF_PATHS_DATA"
            value = "/vm-data/self-moniotor-cluster/grafana/data/"
          }
          # env {
          #   name  = "GF_PATHS_PLUGINS"
          #   value = "/vm-data/self-moniotor-cluster/grafana/plugins/"
          # }
          # env {
          #   name  = "GF_PATHS_PROVISIONING"
          #   value = "/vm-data/self-moniotor-cluster/grafana/provisioning/"
          # }
          # env {
          #   name  = "GF_PATHS_HOME"
          #   value = "/vm-data/self-moniotor-cluster/grafana/home/"
          # }
          # env {
          #   name  = "GF_SERVER_ROOT_URL"
          #   value = "http://${var.configs.domain}/self-monitor-cluster-grafana/"
          # }
        } # end container

        volume {
          name = "self-monitor-cluster-pvc"

          persistent_volume_claim {
            claim_name = "self-monitor-cluster-pvc"
          }
        }
      }
    }
  }
}

data "external" "self-monitor-cluster-grafana-status" {
  depends_on = [kubernetes_deployment.self-monitor-cluster-grafana]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.grafana-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "self-monitor-cluster-grafana-containers" {
  value = [for item in jsondecode(data.external.self-monitor-cluster-grafana-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "self-monitor-cluster-grafana-services" {
  depends_on = [data.external.self-monitor-cluster-grafana-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.grafana-name}-services"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.grafana-name
    }

    port {
      protocol    = "TCP"
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

output "self-monitor-cluster-grafana-services-addr" {
  value = "${kubernetes_service.self-monitor-cluster-grafana-services.spec.0.cluster_ip}:${kubernetes_service.self-monitor-cluster-grafana-services.spec.0.port.0.target_port}"
}
