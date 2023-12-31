# use vmbackup to backup vm-storage data ervery day

locals {
  daily-vm-backup-name = "realtime-cluster-vm-backup-daily"
  yesterday            = formatdate("YYYY-MM-DD", timeadd(timestamp(), "-24h"))
  daily_s3_path        = "s3://${var.configs.s3.AWS_BUCKET}/metrics/vmstorage-backup/realtime-cluster/daily/${local.yesterday}/sharding-"
  daily_instance_count = (length(var.configs.s3.AWS_ACCESS_KEY_ID) > 0 &&
    length(var.configs.s3.AWS_SECRET_ACCESS_KEY) > 0 &&
    length(var.configs.s3.AWS_REGION) > 0 &&
  length(var.configs.s3.AWS_BUCKET) > 0) ? var.configs.realtime_cluster.storage_node_count : 0
  daily_time_array = [for i in range(local.instance_count) : (i * 11 + 4) % 60]
}

resource "kubernetes_cron_job_v1" "realtime-cluster-vm-backup-daily" {
  depends_on = [
    kubernetes_stateful_set.realtime-cluster-vm-storage,
    data.external.realtime-cluster-vm-storage-status
  ]
  count = local.daily_instance_count
  metadata {
    name      = "${local.daily-vm-backup-name}-${count.index}"
    namespace = var.configs.namespace
    labels = {
      k8s-app    = local.daily-vm-backup-name
      node_index = count.index
    }
  }
  spec {
    concurrency_policy        = "Replace"
    failed_jobs_history_limit = 5
    # not at same time
    schedule                      = "${local.daily_time_array[count.index]} 0 * * *" # every day
    timezone                      = "Etc/UTC"
    starting_deadline_seconds     = 100
    successful_jobs_history_limit = 100
    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            container {
              name              = "${local.daily-vm-backup-name}-${count.index}"
              image             = "victoriametrics/vmbackup:${var.configs.vm.version}"
              image_pull_policy = "IfNotPresent"
              args = [
                "-concurrency=1",
                "-dst=${local.daily_s3_path}${count.index}/",
                "-memory.allowedPercent=80",
                "-snapshot.createURL=http://${local.vm_storage_list_for_backup[tostring(count.index)]}/snapshot/create",
                "-storageDataPath=${var.configs.realtime_cluster.storage_path}${count.index}/",
                "-httpListenAddr=:8420",
                #"-loggerDisableTimestamps",
                "-loggerFormat=${var.configs.log.format}",
                "-loggerLevel=${var.configs.log.level}",
                "-loggerOutput=${var.configs.log.output}",
                "-pushmetrics.extraLabel=region=\"${var.configs.region}\"",
                "-pushmetrics.extraLabel=env=\"${var.configs.env}\"",
                "-pushmetrics.extraLabel=cluster=\"realtime-cluster\"",
                "-pushmetrics.extraLabel=role=\"vm-backup-daily\"",
                "-pushmetrics.extraLabel=container_ip=\"$(CONTAINER_IP)\"",
                "-pushmetrics.extraLabel=container_name=\"$(CONTAINER_NAME)\"",
                "-pushmetrics.interval=2s", # must very quick
                "-pushmetrics.url=${var.push_metrics.addr}",
              ]
              resources {
                limits = {
                  cpu    = "1" #todo
                  memory = "1Gi"
                }
                requests = {
                  cpu    = "0.1"
                  memory = "128Mi"
                }
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
                value = "1" #todo
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
  }
}
