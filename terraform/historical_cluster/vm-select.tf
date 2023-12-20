

locals {
  vm-select-name          = "historical-cluster-vm-select"
  port1                   = [for item in jsondecode(data.external.historical-cluster-vm-storage-status.result.r).items : "${item.status.podIP}:8401"]
  port2                   = [for item in jsondecode(data.external.historical-cluster-vm-storage-status.result.r).items : "${item.status.podIP}:18401"]
  storage_list_for_select = join(",", concat(local.port1, local.port2))

  daily_vmselect_count = (length(var.configs.s3.AWS_ACCESS_KEY_ID) > 0 &&
    length(var.configs.s3.AWS_SECRET_ACCESS_KEY) > 0 &&
    length(var.configs.s3.AWS_REGION) > 0 &&
  length(var.configs.s3.AWS_BUCKET) > 0) ? 2 : 0 #todo
}

resource "kubernetes_deployment" "historical-cluster-vm-select" {
  depends_on = [
    data.external.historical-cluster-vm-storage-status
  ]

  metadata {
    namespace = var.configs.namespace
    name      = local.vm-select-name
  }

  spec {
    replicas = local.daily_vmselect_count

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
            "-pushmetrics.extraLabel=cluster=\"historical-cluster\"",
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
              cpu    = "0.5"
              memory = "512Mi"
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

data "external" "historical-cluster-vm-select-status" {
  depends_on = [kubernetes_deployment.historical-cluster-vm-select]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.vm-select-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "historical-cluster-vm-select-containers" {
  value = [for item in jsondecode(data.external.historical-cluster-vm-select-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "historical-cluster-vm-select-services" {
  depends_on = [data.external.historical-cluster-vm-select-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.vm-select-name}-services"
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

output "historical-cluster-vm-select-services-addr" {
  value = "${kubernetes_service.historical-cluster-vm-select-services.spec.0.cluster_ip}:${kubernetes_service.historical-cluster-vm-select-services.spec.0.port.0.target_port}"
}