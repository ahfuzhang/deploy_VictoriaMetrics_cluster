

locals {
  vm-select-name = "realtime-cluster-vm-select"
  #storage_list_for_select = join(",", [for item in jsondecode(data.external.realtime-cluster-vm-storage-status.result.r).items : "${item.status.podIP}:8401"])
  storage_list_for_select = join(",", [for index, item in range(0, var.configs.realtime_cluster.storage_node_count) : "realtime-cluster-vm-storage-service-for-select-${index}:8401"])
}

resource "kubernetes_deployment" "realtime-cluster-vm-select" {
  depends_on = [
    data.external.realtime-cluster-vm-storage-status
  ]

  metadata {
    namespace = var.configs.namespace
    name      = local.vm-select-name
  }

  spec {
    replicas = 2 #todo

    selector {
      match_labels = {
        kubernetes_deployment_name = local.vm-select-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.vm-select-name
        }
      }

      spec {
        container {
          image             = "victoriametrics/vmselect:${var.configs.vm.version}-cluster"
          image_pull_policy = "IfNotPresent"
          args = [
            #"-cacheDataPath=''"
            "-clusternative.maxConcurrentRequests=16",
            "-clusternativeListenAddr=:7401",
            "-dedup.minScrapeInterval=15s",
            "-httpListenAddr=:8481",
            "-loggerDisableTimestamps",
            "-loggerFormat=${var.configs.log.format}",
            "-loggerLevel=${var.configs.log.level}",
            "-loggerOutput=${var.configs.log.output}",
            "-memory.allowedPercent=80",
            "-pushmetrics.extraLabel=region=\"${var.configs.region}\"",
            "-pushmetrics.extraLabel=env=\"${var.configs.env}\"",
            "-pushmetrics.extraLabel=cluster=\"realtime-cluster\"",
            "-pushmetrics.extraLabel=role=\"vm-select\"",
            "-pushmetrics.extraLabel=container_ip=\"$(CONTAINER_IP)\"",
            "-pushmetrics.extraLabel=container_name=\"$(CONTAINER_NAME)\"",
            "-pushmetrics.interval=${var.push_metrics.interval}",
            "-pushmetrics.url=${var.push_metrics.addr}",
            "-replicationFactor=2",
            #"-search.denyPartialResponse",
            "-search.logQueryMemoryUsage=0",
            "-search.logSlowQueryDuration=5s",
            "-search.maxConcurrentRequests=16",
            "-search.maxMemoryPerQuery=0",
            "-search.maxPointsPerTimeseries=86400",
            "-search.maxQueryDuration=60s",
            "-search.maxSeries=1000000",
            "-search.maxUniqueTimeseries=1000000",
            "-storageNode=${local.storage_list_for_select}"
          ]
          name = local.vm-select-name

          resources {
            limits = {
              cpu    = "2" #todo
              memory = "4Gi"
            }
            requests = {
              cpu    = "0.1"
              memory = "256Mi"
            }
          }

          port {
            container_port = 7401
          }
          port {
            container_port = 8481
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

data "external" "realtime-cluster-vm-select-status" {
  depends_on = [kubernetes_deployment.realtime-cluster-vm-select]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.vm-select-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "realtime-cluster-vm-select-containers" {
  value = [for item in jsondecode(data.external.realtime-cluster-vm-select-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "realtime-cluster-vm-select-service" {
  depends_on = [data.external.realtime-cluster-vm-select-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.vm-select-name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.vm-select-name
    }

    port {
      protocol    = "TCP"
      port        = 8481
      target_port = 8481
    }

    type = "ClusterIP"
  }
}

output "realtime-cluster-vm-select-service-addr" {
  value = "${kubernetes_service.realtime-cluster-vm-select-service.spec.0.cluster_ip}:${kubernetes_service.realtime-cluster-vm-select-service.spec.0.port.0.target_port}"
}
