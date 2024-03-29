

locals {
  vm-storage-name = "realtime-cluster-vm-storage"
  #vm-storage-basepath = "/vm-data/"
  #storage_data_path   = "${local.vm-storage-basepath}realtime-cluster/sharding-"
}

resource "kubernetes_stateful_set" "realtime-cluster-vm-storage" {
  #depends_on = [kubernetes_persistent_volume_claim.realtime-cluster-pvc]
  count = var.configs.realtime_cluster.storage_node_count
  metadata {
    namespace = var.configs.namespace

    labels = {
      k8s-app    = local.vm-storage-name
      node_index = count.index
    }

    name = "${local.vm-storage-name}-${count.index}"
  }

  spec {
    pod_management_policy  = "OrderedReady"
    replicas               = 1
    revision_history_limit = 5

    selector {
      match_labels = {
        k8s-app    = local.vm-storage-name
        node_index = count.index
      }
    }

    service_name = "${local.vm-storage-name}-${count.index}"

    template {
      metadata {
        labels = {
          k8s-app    = local.vm-storage-name
          node_index = count.index
        }

        annotations = {}
      }

      spec {
        container {
          name              = "${local.vm-storage-name}-${count.index}"
          image             = "victoriametrics/vmstorage:${var.configs.vm.version}-cluster"
          image_pull_policy = "IfNotPresent"
          args = [
            "-blockcache.missesBeforeCaching=2",
            "-cacheExpireDuration=30m",
            "-dedup.minScrapeInterval=15s",
            "-denyQueriesOutsideRetention",
            "-finalMergeDelay=0s",
            "-httpListenAddr=:8482",
            "-insert.maxQueueDuration=1m",
            "-loggerDisableTimestamps",
            "-loggerFormat=${var.configs.log.format}",
            "-loggerLevel=${var.configs.log.level}",
            "-loggerOutput=${var.configs.log.output}",
            "-maxConcurrentInserts=16",
            "-memory.allowedPercent=80",
            "-retentionPeriod=15d", #todo
            "-search.maxConcurrentRequests=32",
            "-search.maxUniqueTimeseries=1000000",
            "-snapshotsMaxAge=1d",
            "-storage.cacheSizeIndexDBDataBlocks=0",
            "-storage.cacheSizeIndexDBIndexBlocks=0",
            "-storage.cacheSizeIndexDBTagFilters=0",
            "-storage.cacheSizeStorageTSID=0",
            "-storage.maxDailySeries=100000000",
            "-storage.maxHourlySeries=50000000",
            "-storage.minFreeDiskSpaceBytes=5GB",
            "-storageDataPath=${var.configs.realtime_cluster.storage_path}${count.index}/",
            "-vminsertAddr=:8400",
            "-vmselectAddr=:8401",
            "-pushmetrics.extraLabel=region=\"${var.configs.region}\"",
            "-pushmetrics.extraLabel=env=\"${var.configs.env}\"",
            "-pushmetrics.extraLabel=cluster=\"realtime-cluster\"",
            "-pushmetrics.extraLabel=role=\"vm-storage\"",
            "-pushmetrics.extraLabel=container_ip=\"$(CONTAINER_IP)\"",
            "-pushmetrics.extraLabel=container_name=\"$(CONTAINER_NAME)\"",
            "-pushmetrics.interval=${var.push_metrics.interval}",
            "-pushmetrics.url=${var.push_metrics.addr}",
          ]
          resources {
            limits = {
              cpu    = "4" #todo
              memory = "32Gi"
            }
            requests = {
              cpu    = "0.1"
              memory = "4Gi"
            }
          }
          port {
            container_port = 8482
          }
          port {
            container_port = 8400
          }
          port {
            container_port = 8401
          }
          volume_mount {
            name       = "realtime-cluster-pvc"
            mount_path = var.configs.pvc.basepath
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
            value = "4" #todo
          }
        } # end container

        termination_grace_period_seconds = 300

        volume {
          name = "realtime-cluster-pvc"
          persistent_volume_claim {
            claim_name = "realtime-cluster-pvc"
          }
        }
      } #end spec

    }

    update_strategy {
      type = "RollingUpdate"

      # rolling_update {
      #   partition = 1
      # }
    }

  }
}

data "external" "realtime-cluster-vm-storage-status" {
  depends_on = [kubernetes_stateful_set.realtime-cluster-vm-storage]
  program    = ["bash", "-c", "kubectl get pods -l k8s-app=${local.vm-storage-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "realtime-cluster-vm-storage-containers" {
  value = [for item in jsondecode(data.external.realtime-cluster-vm-storage-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

//-----------------------------------------------------------------------------
resource "kubernetes_service" "realtime-cluster-vm-storage-service-for-insert" {
  depends_on = [kubernetes_stateful_set.realtime-cluster-vm-storage]
  count      = var.configs.realtime_cluster.storage_node_count
  metadata {
    namespace = var.configs.namespace
    name      = "${local.vm-storage-name}-service-for-insert-${count.index}"
    labels = {
      k8s-app    = "${local.vm-storage-name}-service-for-insert"
      node_index = count.index
    }
  }

  spec {
    selector = {
      k8s-app    = local.vm-storage-name
      node_index = count.index
    }

    port {
      protocol    = "TCP"
      port        = 8400
      target_port = 8400
    }

    type = "ClusterIP"
  }
}

data "external" "realtime-cluster-vm-storage-service-for-insert-status" {
  depends_on = [kubernetes_service.realtime-cluster-vm-storage-service-for-insert]
  program    = ["bash", "-c", "kubectl get service -l k8s-app=${local.vm-storage-name}-service-for-insert -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "realtime-cluster-vm-storage-service-list-for-insert" {
  value = [for item in jsondecode(data.external.realtime-cluster-vm-storage-service-for-insert-status.result.r).items : item.spec.clusterIP]
}

//-----------------------------------------------------------------------------
resource "kubernetes_service" "realtime-cluster-vm-storage-service-for-select" {
  depends_on = [kubernetes_stateful_set.realtime-cluster-vm-storage]
  count      = var.configs.realtime_cluster.storage_node_count
  metadata {
    namespace = var.configs.namespace
    name      = "${local.vm-storage-name}-service-for-select-${count.index}"
    labels = {
      k8s-app    = "${local.vm-storage-name}-service-for-select"
      node_index = count.index
    }
  }

  spec {
    selector = {
      k8s-app    = local.vm-storage-name
      node_index = count.index
    }

    port {
      protocol    = "TCP"
      port        = 8401
      target_port = 8401
    }

    type = "ClusterIP"
  }
}

data "external" "realtime-cluster-vm-storage-service-for-select-status" {
  depends_on = [kubernetes_service.realtime-cluster-vm-storage-service-for-select]
  program    = ["bash", "-c", "kubectl get service -l k8s-app=${local.vm-storage-name}-service-for-select -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "realtime-cluster-vm-storage-service-list-for-select" {
  value = [for item in jsondecode(data.external.realtime-cluster-vm-storage-service-for-select-status.result.r).items : item.spec.clusterIP]
}
