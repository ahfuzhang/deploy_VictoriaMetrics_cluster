locals {
  dingtalk-webhook-name = "alert-cluster-dingtalk-webhook"
  log_level             = lower(var.configs.log.level)
}

resource "kubernetes_config_map" "alert-cluster-dingtalk-webhook-configs" {
  metadata {
    name      = "alert-cluster-dingtalk-webhook-configs"
    namespace = var.configs.namespace
  }

  data = {
    "webhook-dingtalk.yaml" = <<EOF
targets:
  # support only one webhook link at this example
  webhook1:
    url: "${var.configs.dingtalk_webhooks[0].url}"
    secret: "${var.configs.dingtalk_webhooks[0].secret}"

    EOF
  }
}

resource "kubernetes_deployment" "alert-cluster-dingtalk-webhook" {
  metadata {
    namespace = var.configs.namespace
    name      = local.dingtalk-webhook-name
  }

  spec {
    replicas = 2 #todo

    selector {
      match_labels = {
        kubernetes_deployment_name = local.dingtalk-webhook-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.dingtalk-webhook-name
        }
      }

      spec {
        container {
          image             = "ahfuzhang/dingtalk-webhook:v2.1.1"
          image_pull_policy = "IfNotPresent"
          args = [
            "--web.listen-address=:8060",
            "--web.enable-ui",
            "--config.file=/configs/webhook-dingtalk.yaml",
            "--log.level=${local.log_level}",
            "--log.format=${var.configs.log.format}",
            "--pushmetrics.extraLabel='region=\"${var.configs.region}\",env=\"${var.configs.env}\",cluster=\"alert-cluster\",role=\"dingtalk-webhook\",container_ip=\"$(CONTAINER_IP)\",container_name=\"$(CONTAINER_NAME)\"'",
            "--pushmetrics.interval=${var.push_metrics.interval}",
            "--pushmetrics.url=${var.push_metrics.addr}",
            "--maxalertcount=30", # todo: use config
          ]
          name = local.dingtalk-webhook-name

          resources {
            limits = {
              cpu    = "0.5" #todo
              memory = "256Mi"
            }
            requests = {
              cpu    = "0.1"
              memory = "128Mi"
            }
          }

          port {
            container_port = 8060
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
            name       = "alert-cluster-dingtalk-webhook-configs-volume"
            mount_path = "/configs/"
          }
        } # end container
        volume {
          name = "alert-cluster-dingtalk-webhook-configs-volume"

          config_map {
            name = "alert-cluster-dingtalk-webhook-configs"
          }
        }
      }
    }
  }
}

data "external" "alert-cluster-dingtalk-webhook-status" {
  depends_on = [kubernetes_deployment.alert-cluster-dingtalk-webhook]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.dingtalk-webhook-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "alert-cluster-dingtalk-webhook-containers" {
  value = [for item in jsondecode(data.external.alert-cluster-dingtalk-webhook-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "alert-cluster-dingtalk-webhook-service" {
  depends_on = [data.external.alert-cluster-dingtalk-webhook-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.dingtalk-webhook-name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.dingtalk-webhook-name
    }

    port {
      protocol    = "TCP"
      port        = 8060
      target_port = 8060
    }

    type = "ClusterIP"
  }
}

output "alert-cluster-dingtalk-webhook-service-addr" {
  value = "${kubernetes_service.alert-cluster-dingtalk-webhook-service.spec.0.cluster_ip}:${kubernetes_service.alert-cluster-dingtalk-webhook-service.spec.0.port.0.target_port}"
}
