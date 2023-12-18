

locals {
  vm-insert-name = "realtime-cluster-vm-insert"
  storage_list   = join(",", [for item in jsondecode(data.external.realtime-cluster-vm-storage-status.result.r).items : "${item.status.podIP}:8400"])
}

resource "kubernetes_deployment" "realtime-cluster-vm-insert" {
  depends_on = [
    data.external.realtime-cluster-vm-storage-status
  ]

  metadata {
    namespace = var.configs.namespace
    name      = local.vm-insert-name
  }

  spec {
    replicas = 2  #todo

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
            "-replicationFactor=2",  #todo
            "-storageNode=${local.storage_list}",
            "-pushmetrics.extraLabel=region=\"${var.configs.region}\"",
            "-pushmetrics.extraLabel=env=\"${var.configs.env}\"",
            "-pushmetrics.extraLabel=cluster=\"realtime-cluster\"",
            "-pushmetrics.extraLabel=role=\"vm-insert\"",
            "-pushmetrics.extraLabel=container_ip=\"$(CONTAINER_IP)\"",
            "-pushmetrics.extraLabel=container_name=\"$(CONTAINER_NAME)\"",
            "-pushmetrics.interval=${var.push_metrics.interval}",
            "-pushmetrics.url=${var.push_metrics.addr}",
          ]
          name = local.vm-insert-name

          resources {
            limits = {
              cpu    = "2"  #todo
              memory = "2Gi"
            }
            requests = {
              cpu    = "2"
              memory = "2Gi"
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
            value = "2"  #todo
          }
        } # end container

      }
    }
  }
}

data "external" "realtime-cluster-vm-insert-status" {
  depends_on = [kubernetes_deployment.realtime-cluster-vm-insert]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.vm-insert-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "realtime-cluster-vm-insert-containers" {
  value = [for item in jsondecode(data.external.realtime-cluster-vm-insert-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "realtime-cluster-vm-insert-services" {
  depends_on = [data.external.realtime-cluster-vm-insert-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.vm-insert-name}-services"
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

output "realtime-cluster-vm-insert-services-addr" {
  value = "${kubernetes_service.realtime-cluster-vm-insert-services.spec.0.cluster_ip}:${kubernetes_service.realtime-cluster-vm-insert-services.spec.0.port.0.target_port}"
}
