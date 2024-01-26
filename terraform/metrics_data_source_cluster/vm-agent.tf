# todo
# 把本次部署的所有 exporter 的数据进行采集，然后发给 realtime-cluster
# 注意：这是用于测试的，需要在有其他的真实数据后，修改  exporters.yaml

locals {
  name  = "metrics-data-source-cluster-vm-agent"
  count = 2 #todo
}

resource "kubernetes_config_map" "metrics-data-source-cluster-vm-agent-file-sd" {
  depends_on = [data.external.self-monitor-cluster-vm-agent-status]
  metadata {
    name      = "${local.name}-file-sd"
    namespace = var.configs.namespace
  }

  data = {
    "file_sd_configs.yaml" = <<EOF
#file_sd_configs
scrape_configs:
- job_name: file
  file_sd_configs:
    # files must contain a list of file patterns for files with scrape targets.
    # The last path segment can contain `*`, which matches any number of chars in file name.
  - files:
    #- "my/path/*.yaml"
    #- "another/path.json"
    - "/exporters/exporters.yaml"  # todo
  # relabel_configs:
  #   - source_labels: ['__address__']
  #     target_label: 'container_ip'
  #   - source_labels: [container_ip]
  #     regex: (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})
  #     replacement: ${1}
  #     target_label: container_ip
	EOF
  }
}

data "kubernetes_config_map" "self-monitor-cluster-vm-agent-exporters-data" {
  depends_on = [data.external.self-monitor-cluster-vm-agent-status]
  metadata {
    name      = "self-monitor-cluster-vm-agent-exporters"
    namespace = var.configs.namespace
  }
}

locals {
  exporters = data.kubernetes_config_map.self-monitor-cluster-vm-agent-exporters-data.data != null ? data.kubernetes_config_map.self-monitor-cluster-vm-agent-exporters-data.data["exporters.yaml"] : "" # todo: release version, delete this
}

locals {
  realtime_vm_storage_list_for_metrics = join(",", [for item in var.realtime_cluster_info.vm_storage_list : "\"http://${item.container_ip}:8482/metrics\""])
  realtime_vm_insert_list_for_metrics  = join(",", [for item in var.realtime_cluster_info.vm_insert_list : "\"http://${item.container_ip}:8480/metrics\""])
  realtime_vm_select_list_for_metrics  = join(",", [for item in var.realtime_cluster_info.vm_select_list : "\"http://${item.container_ip}:8481/metrics\""])
}

locals {
  #alert_dingtalk_webhook_list_for_metrics = join(",", [for item in var.alert_cluster_info.dingtalk_webhook_list : "\"http://${item.container_ip}:8060/metrics\""])
  #alert_alert_manager_list_for_metrics = join(",", [for item in var.alert_cluster_info.alert_manager_list : "\"http://${item.container_ip}:9093/metrics\""])
  alert_vm_alert_list_for_metrics = join(",", [for item in var.alert_cluster_info.vm_alert_list : "\"http://${item.container_ip}:8880/alert-cluster-vm-alert/metrics\""])
}

resource "kubernetes_config_map" "metrics-data-source-cluster-vm-agent-exporters" {
  depends_on = [data.external.self-monitor-cluster-vm-agent-status]
  metadata {
    name      = "${local.name}-exporters"
    namespace = var.configs.namespace
  }
  # todo: 获取数据
  data = {
    "exporters.yaml" = <<EOF
${local.exporters}  #todo: release version, delete this
- targets: [${local.realtime_vm_storage_list_for_metrics}]
  labels:
    "from": "vm-agent"
    "region": "${var.configs.region}"
    "env": "${var.configs.env}"
    "cluster": "realtime-cluster"
    "role": "vm-storage"
- targets: [${local.realtime_vm_insert_list_for_metrics}]
  labels:
    "from": "vm-agent"
    "region": "${var.configs.region}"
    "env": "${var.configs.env}"
    "cluster": "realtime-cluster"
    "role": "vm-insert"
- targets: [${local.realtime_vm_select_list_for_metrics}]
  labels:
    "from": "vm-agent"
    "region": "${var.configs.region}"
    "env": "${var.configs.env}"
    "cluster": "realtime-cluster"
    "role": "vm-select"
####################
- targets: [${local.alert_vm_alert_list_for_metrics}]
  labels:
    "from": "vm-agent"
    "region": "${var.configs.region}"
    "env": "${var.configs.env}"
    "cluster": "alert-cluster"
    "role": "vm-alert"
####################
# for test
- targets: ["http://10.151.0.71:32102/metrics"]
  labels:
    "from": "vm-agent"
    "region": "${var.configs.region}"
    "env": "${var.configs.env}"
    "cluster": "metrics-data-source-cluster"
    "role": "app"
    EOF
  }
}

resource "kubernetes_deployment" "metrics-data-source-cluster-vm-agent" {
  depends_on = [
    kubernetes_config_map.metrics-data-source-cluster-vm-agent-file-sd,
    kubernetes_config_map.metrics-data-source-cluster-vm-agent-exporters
  ]
  count = local.count

  metadata {
    namespace = var.configs.namespace
    name      = "${local.name}-${count.index}"
    labels = {
      kubernetes_deployment_name = local.name
      node_index                 = count.index
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        kubernetes_deployment_name = local.name
        node_index                 = count.index
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.name
          node_index                 = count.index
        }
      }

      spec {
        container {
          image             = "victoriametrics/vmagent:${var.configs.vm.version}"
          image_pull_policy = "IfNotPresent"
          args = [
            "-httpListenAddr=:8429",
            "-http.pathPrefix=/metrics-data-source-cluster-vm-agent/",
            "-loggerDisableTimestamps",
            "-loggerFormat=${var.configs.log.format}",
            "-loggerLevel=${var.configs.log.level}",
            "-loggerOutput=${var.configs.log.output}",
            "-maxConcurrentInserts=8",
            "-maxInsertRequestSize=32MB",
            "-memory.allowedPercent=80",
            #"-promscrape.cluster.memberLabel=''",
            "-pushmetrics.extraLabel=region=\"${var.configs.region}\"",
            "-pushmetrics.extraLabel=env=\"${var.configs.env}\"",
            "-pushmetrics.extraLabel=cluster=\"metrics-data-source-cluster\"",
            "-pushmetrics.extraLabel=role=\"vm-agent\"",
            "-pushmetrics.extraLabel=container_ip=\"$(CONTAINER_IP)\"",
            "-pushmetrics.extraLabel=container_name=\"$(CONTAINER_NAME)\"",
            "-pushmetrics.interval=15s",
            "-pushmetrics.url=${var.push_metrics.addr}",
            "-promscrape.cluster.memberNum=${count.index}",
            "-promscrape.cluster.membersCount=${local.vm-agent-count}",
            "-promscrape.cluster.name=self-monitor-cluster-vm-agent-${count.index}",
            "-promscrape.cluster.replicationFactor=1",
            "-promscrape.config.strictParse",
            "-promscrape.configCheckInterval=1m",
            "-promscrape.fileSDCheckInterval=1m",
            "-promscrape.httpSDCheckInterval=1m",
            "-promscrape.maxScrapeSize=16MB",
            "-promscrape.seriesLimitPerTarget=50000",
            "-remoteWrite.disableOnDiskQueue",
            "-remoteWrite.dropSamplesOnOverload=1",
            "-remoteWrite.flushInterval=15s",
            #"-remoteWrite.label=''",
            #"-remoteWrite.url=http://$${var.realtime_cluster_info.insert_addr}/insert/0/prometheus/api/v1/write",
            "-remoteWrite.url=http://realtime-cluster-vm-insert-service:8480/insert/0/prometheus/api/v1/write",
            "-promscrape.config=/configs/file_sd_configs.yaml",
          ]
          name = "${local.vm-agent-name}-${count.index}"

          resources {
            limits = {
              cpu    = "2" # todo
              memory = "1Gi"
            }
            requests = {
              cpu    = "0.1"
              memory = "256Mi"
            }
          }

          port {
            container_port = 8429
          }

          volume_mount {
            name       = "file-sd-config-volume"
            mount_path = "/configs/"
          }

          volume_mount {
            name       = "exporters-config-volume"
            mount_path = "/exporters/"
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
            value = "2" # todo
          }
        } # end container

        volume {
          name = "file-sd-config-volume"

          config_map {
            name = "metrics-data-source-cluster-vm-agent-file-sd"
          }
        }

        volume {
          name = "exporters-config-volume"

          config_map {
            name = "metrics-data-source-cluster-vm-agent-exporters"
          }
        }
      }
    }
  }
}

data "external" "metrics-data-source-cluster-vm-agent-status" {
  depends_on = [kubernetes_deployment.metrics-data-source-cluster-vm-agent]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "metrics-data-source-cluster-vm-agent-containers" {
  value = [for item in jsondecode(data.external.metrics-data-source-cluster-vm-agent-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "metrics-data-source-cluster-vm-agent-service" {
  depends_on = [data.external.metrics-data-source-cluster-vm-agent-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.name
    }

    port {
      protocol    = "TCP"
      port        = 8429
      target_port = 8429
    }

    type = "ClusterIP"
  }
}

output "metrics-data-source-cluster-vm-agent-service-addr" {
  value = "${kubernetes_service.metrics-data-source-cluster-vm-agent-service.spec.0.cluster_ip}:${kubernetes_service.metrics-data-source-cluster-vm-agent-service.spec.0.port.0.target_port}"
}
