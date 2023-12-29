locals {
  alert-manager-name    = "alert-cluster-alert-manager"
  dingtalk_webhook_addr = "${kubernetes_service.alert-cluster-dingtalk-webhook-service.spec.0.cluster_ip}:${kubernetes_service.alert-cluster-dingtalk-webhook-service.spec.0.port.0.target_port}"
}

resource "kubernetes_config_map" "alert-cluster-alert-manager-configs" {
  metadata {
    name      = "alert-cluster-alert-manager-configs"
    namespace = var.configs.namespace
  }

  data = {
    "alertmanager.yaml" = <<EOF
global:
  resolve_timeout: 10m
receivers:
- name: 'webhook1'
  webhook_configs:
  - url: 'http://${local.dingtalk_webhook_addr}/dingtalk/webhook1/send'
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 1m
  repeat_interval: 1m
  receiver: 'webhook1'

    EOF
  }
}

resource "kubernetes_deployment" "alert-cluster-alert-manager-main" {
  depends_on = [
    kubernetes_deployment.alert-cluster-dingtalk-webhook,
    kubernetes_config_map.alert-cluster-alert-manager-configs
  ]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.alert-manager-name}-main"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        kubernetes_deployment_name = local.alert-manager-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.alert-manager-name
        }
      }

      spec {
        container {
          image             = "prom/alertmanager:v0.25.1"
          image_pull_policy = "IfNotPresent"
          args = [
            "--config.file=/configs/alertmanager.yaml",
            "--alerts.gc-interval=30m",
            "--no-web.systemd-socket",
            "--web.listen-address=:9093",
            "--cluster.listen-address=:9094",
            "--cluster.advertise-address=:9094",
            #"--cluster.peer=", # 第一个节点填空
            "--cluster.gossip-interval=200ms",
            "--cluster.pushpull-interval=1m0s",
            "--cluster.tcp-timeout=10s",
            #"--cluster.label='alert-manager-main'",
            "--log.level=${local.log_level}",
            "--log.format=${var.configs.log.format}",
          ]
          name = "${local.alert-manager-name}-main"

          resources {
            limits = {
              cpu    = "1" #todo
              memory = "512Mi"
            }
            requests = {
              cpu    = "1"
              memory = "512Mi"
            }
          }

          port {
            container_port = 9093
          }
          port {
            container_port = 9094
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
            value = "1" #todo
          }

          volume_mount {
            name       = "alert-cluster-alert-manager-configs-volume"
            mount_path = "/configs/"
          }
        } # end container
        volume {
          name = "alert-cluster-alert-manager-configs-volume"

          config_map {
            name = "alert-cluster-alert-manager-configs"
          }
        }
      }
    }
  }
}

data "external" "alert-cluster-alert-manager-main-status" {
  depends_on = [kubernetes_deployment.alert-cluster-alert-manager-main]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.alert-manager-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

// 拿到第一个容器的 ip, 然后配置 gosip 算法
locals {
  alert-manager-main = jsondecode(data.external.alert-cluster-alert-manager-main-status.result.r).items.0.status.podIP
}

resource "kubernetes_deployment" "alert-cluster-alert-manager-secondary" {
  depends_on = [data.external.alert-cluster-alert-manager-main-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.alert-manager-name}-secondary"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        kubernetes_deployment_name = local.alert-manager-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.alert-manager-name
        }
      }

      spec {
        container {
          image             = "prom/alertmanager:v0.25.1"
          image_pull_policy = "IfNotPresent"
          args = [
            "--config.file=/configs/alertmanager.yaml",
            "--alerts.gc-interval=30m",
            "--no-web.systemd-socket",
            "--web.listen-address=:9093",
            "--cluster.listen-address=:9094",
            "--cluster.advertise-address=:9094",
            "--cluster.peer=${local.alert-manager-main}:9094",
            "--cluster.gossip-interval=200ms",
            "--cluster.pushpull-interval=1m0s",
            "--cluster.tcp-timeout=10s",
            #"--cluster.label='alert-manager-secondary'",
            "--log.level=${local.log_level}",
            "--log.format=${var.configs.log.format}",
          ]
          name = "${local.alert-manager-name}-secondary"

          resources {
            limits = {
              cpu    = "1" #todo
              memory = "512Mi"
            }
            requests = {
              cpu    = "0.1"
              memory = "128Mi"
            }
          }

          port {
            container_port = 9093
          }
          port {
            container_port = 9094
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
            value = "1" #todo
          }

          volume_mount {
            name       = "alert-cluster-alert-manager-configs-volume"
            mount_path = "/configs/"
          }
        } # end container
        volume {
          name = "alert-cluster-alert-manager-configs-volume"

          config_map {
            name = "alert-cluster-alert-manager-configs"
          }
        }
      }
    }
  }
}

data "external" "alert-cluster-alert-manager-status" {
  depends_on = [kubernetes_deployment.alert-cluster-alert-manager-main, kubernetes_deployment.alert-cluster-alert-manager-secondary]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.alert-manager-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "alert-cluster-alert-manager-containers" {
  value = [for item in jsondecode(data.external.alert-cluster-alert-manager-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "alert-cluster-alert-manager-service" {
  depends_on = [data.external.alert-cluster-alert-manager-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.alert-manager-name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.alert-manager-name
    }

    port {
      protocol    = "TCP"
      port        = 9093
      target_port = 9093
    }

    type = "ClusterIP"
  }
}

output "alert-cluster-alert-manager-service-addr" {
  value = "${kubernetes_service.alert-cluster-alert-manager-service.spec.0.cluster_ip}:${kubernetes_service.alert-cluster-alert-manager-service.spec.0.port.0.target_port}"
}
