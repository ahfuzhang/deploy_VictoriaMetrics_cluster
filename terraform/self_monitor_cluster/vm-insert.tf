

locals {
  vm-insert-name = "self-monitor-cluster-vm-insert"
  #storage_list_for_insert = join(",", [for item in jsondecode(data.external.self-monitor-cluster-vm-storage-status.result.r).items : "${item.status.podIP}:8400"])
  storage_list_for_insert = join(",", [for index, item in range(0, local.vm-storage-count) : "self-monitor-cluster-vm-storage-service-for-insert-${index}:8400"])
}

resource "kubernetes_deployment" "self-monitor-cluster-vm-insert" {
  depends_on = [
    data.external.self-monitor-cluster-vm-storage-status
  ]

  metadata {
    namespace = var.configs.namespace
    name      = local.vm-insert-name
  }

  spec {
    replicas = 2 #todo

    selector {
      match_labels = {
        kubernetes_deployment_name = local.vm-insert-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.vm-insert-name
        }
      }

      spec {
        container {
          image             = "victoriametrics/vminsert:${var.configs.vm.version}-cluster"
          image_pull_policy = "IfNotPresent"
          args = [
            "-clusternativeListenAddr=:7400",
            "-dropSamplesOnOverload",
            "-httpListenAddr=:8480",
            "-http.pathPrefix=/self-monitor-cluster-insert/",
            "-insert.maxQueueDuration=1m",
            "-loggerDisableTimestamps",
            "-loggerFormat=${var.configs.log.format}",
            "-loggerLevel=${var.configs.log.level}",
            "-loggerOutput=${var.configs.log.output}",
            "-maxConcurrentInserts=8",
            "-maxInsertRequestSize=32MB",
            "-maxLabelValueLen=1024",
            "-maxLabelsPerTimeseries=30",
            "-memory.allowedPercent=80",
            "-replicationFactor=2",
            "-storageNode=${local.storage_list_for_insert}",
          ]
          name = local.vm-insert-name

          resources {
            limits = {
              cpu    = "2" #todo
              memory = "2Gi"
            }
            requests = {
              cpu    = "0.1"
              memory = "128Mi"
            }
          }

          port {
            container_port = 7400
          }
          port {
            container_port = 8480
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
            value = "2" #todo
          }
        } # end container

      }
    }
  }
}

data "external" "self-monitor-cluster-vm-insert-status" {
  depends_on = [kubernetes_deployment.self-monitor-cluster-vm-insert]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.vm-insert-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "self-monitor-cluster-vm-insert-containers" {
  value = [for item in jsondecode(data.external.self-monitor-cluster-vm-insert-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "self-monitor-cluster-vm-insert-service" {
  depends_on = [data.external.self-monitor-cluster-vm-insert-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.vm-insert-name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.vm-insert-name
    }

    port {
      protocol    = "TCP"
      port        = 8480
      target_port = 8480
    }

    type = "ClusterIP"
  }
}

output "self-monitor-cluster-vm-insert-service-addr" {
  value = "${kubernetes_service.self-monitor-cluster-vm-insert-service.spec.0.cluster_ip}:${kubernetes_service.self-monitor-cluster-vm-insert-service.spec.0.port.0.target_port}"
}
