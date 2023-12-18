

locals {
  grafana-name = "realtime-cluster-grafana"
}

resource "kubernetes_deployment" "realtime-cluster-grafana" {

  metadata {
    namespace = var.configs.namespace
    name      = local.grafana-name
    labels = {
      kubernetes_deployment_name = local.grafana-name
    }
  }

  spec {
    replicas = 1  #todo

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
              cpu    = "1"  #todo
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
            name       = "realtime-cluster-pvc"
            mount_path = "/vm-data/realtime-cluster/grafana/"
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
            value = "1"  #todo
          }

          # env {
          #   name  = "GF_SECURITY_ADMIN_USER"
          #   value = "admin"
          # }
          # env {
          #   name  = "GF_SECURITY_ADMIN_PASSWORD"
          #   value = "admin"
          # }
          env {
            name  = "GF_PATHS_DATA"
            value = "/vm-data/realtime-cluster/grafana/data/"
          }

        } # end container

        volume {
          name = "realtime-cluster-pvc"

          persistent_volume_claim {
            claim_name = "realtime-cluster-pvc"
          }
        }
      }
    }
  }
}

data "external" "realtime-cluster-grafana-status" {
  depends_on = [kubernetes_deployment.realtime-cluster-grafana]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.grafana-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "realtime-cluster-grafana-containers" {
  value = [for item in jsondecode(data.external.realtime-cluster-grafana-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "realtime-cluster-grafana-services" {
  depends_on = [data.external.realtime-cluster-grafana-status]
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

output "realtime-cluster-grafana-services-addr" {
  value = "${kubernetes_service.realtime-cluster-grafana-services.spec.0.cluster_ip}:${kubernetes_service.realtime-cluster-grafana-services.spec.0.port.0.target_port}"
}
