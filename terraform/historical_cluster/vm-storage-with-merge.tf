

locals {
  vm-storage-name-with-merge = "historical-cluster-vm-storage-with-merge"
  #vm-storage-basepath = "/vm-data/"
  #storage_data_path   = "${local.vm-storage-basepath}historical-cluster/sharding-"
  daily_vmstorage_count_of_merge = (length(var.configs.s3.AWS_ACCESS_KEY_ID) > 0 &&
    length(var.configs.s3.AWS_SECRET_ACCESS_KEY) > 0 &&
    length(var.configs.s3.AWS_REGION) > 0 &&
  length(var.configs.s3.AWS_BUCKET) > 0) ? 1 : 0
}

resource "kubernetes_stateful_set" "historical-cluster-vm-storage-with-merge" {
  count = local.daily_vmstorage_count_of_merge
  metadata {
    namespace = var.configs.namespace

    labels = {
      k8s-app    = local.vm-storage-name-with-merge
      node_index = count.index
    }

    name = "${local.vm-storage-name-with-merge}-${count.index}"
  }

  spec {
    pod_management_policy  = "OrderedReady"
    replicas               = 1
    revision_history_limit = 5

    selector {
      match_labels = {
        k8s-app    = local.vm-storage-name-with-merge
        node_index = count.index
      }
    }

    service_name = "${local.vm-storage-name-with-merge}-${count.index}"

    template {
      metadata {
        labels = {
          k8s-app    = local.vm-storage-name-with-merge
          node_index = count.index
        }

        annotations = {}
      }

      spec {
        container {
          name              = "${local.vm-storage-name-with-merge}-${count.index}"
          image             = "ahfuzhang/vm-historical:v1.95.1-vmfile"
          image_pull_policy = "Always" #"IfNotPresent"
          command           = ["/bin/sh"]
          args = [
            #"-x",  # use debug=1 to show script log
            "/daily_with_vmfile.sh",
          ]
          resources {
            limits = {
              cpu    = "4" #todo
              memory = "32Gi"
            }
            requests = {
              cpu    = "0.1"
              memory = "512Mi"
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
          port {
            container_port = 18482
          }
          port {
            container_port = 18400
          }
          port {
            container_port = 18401
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
          #--------------------------------------------------------------------
          env {
            name  = "configs_namespace"
            value = var.configs.namespace
          }
          env {
            name  = "configs_region"
            value = var.configs.region
          }
          env {
            name  = "configs_env"
            value = var.configs.env
          }
          env {
            name  = "configs_log_format"
            value = var.configs.log.format
          }
          env {
            name  = "configs_log_level"
            value = var.configs.log.level
          }
          env {
            name  = "configs_log_output"
            value = var.configs.log.output
          }
          env {
            name  = "configs_vm_version"
            value = var.configs.vm.version
          }
          env {
            name  = "sharding_count"
            value = local.daily_vmstorage_count
          }
          env {
            name  = "sharding_prefix"
            value = "sharding-"
          }
          env {
            name  = "dedup_minScrapeInterval"
            value = "15s"
          }
          env {
            name  = "n_days_before"
            value = "4"
            # yesterday = 1
            # the day before yesterday = 2
            # 15 before days = 15
          }
          env {
            name  = "debug"
            value = "1" # set empty or 0 to disable debug mode; set debug=1 to enable
          }
          env {
            name  = "storage_base_path"
            value = "/vm-data/historical-cluster/after_merge/"
          }
          env {
            name  = "s3_storage_base_path"
            value = "/metrics/vmstorage-backup/realtime-cluster/daily/"
          }
          env {
            name  = "push_metrics_addr"
            value = var.push_metrics.addr
          }
          env {
            name  = "AWS_ACCESS_KEY_ID"
            value = var.configs.s3.AWS_ACCESS_KEY_ID
          }
          env {
            name  = "AWS_SECRET_ACCESS_KEY"
            value = var.configs.s3.AWS_SECRET_ACCESS_KEY
          }
          env {
            name  = "AWS_REGION"
            value = var.configs.s3.AWS_REGION
          }
          env {
            name  = "AWS_BUCKET"
            value = var.configs.s3.AWS_BUCKET
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

  lifecycle {
    create_before_destroy = true # 例如，创建新资源之前先销毁旧资源
    #prevent_destroy = false       # 控制是否防止资源被销毁
  }
  timeouts {
    create = "5m"
    delete = "30s" # 设置销毁资源的最长等待时间为15分钟
  }
}

data "external" "historical-cluster-vm-storage-with-merge-status" {
  depends_on = [kubernetes_stateful_set.historical-cluster-vm-storage-with-merge]
  program    = ["bash", "-c", "kubectl get pods -l k8s-app=${local.vm-storage-name-with-merge} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "historical-cluster-vm-storage-with-merge-containers" {
  value = [for item in jsondecode(data.external.historical-cluster-vm-storage-with-merge-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}
