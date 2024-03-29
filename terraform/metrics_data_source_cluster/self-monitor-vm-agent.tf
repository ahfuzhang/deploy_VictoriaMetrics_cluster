# 自监控群集的 vm-agent


locals {
  vm-agent-name  = "self-monitor-cluster-vm-agent"
  vm-agent-count = 2 #todo
  #vm-storage_list_for_metrics = join(",", [for item in var.self_monitor_cluster_info.vm_storage_list : "\"http://${item.container_ip}:8482/metrics\""])
  #vm-insert_list_for_metrics  = join(",", [for item in var.self_monitor_cluster_info.vm_insert_list : "\"http://${item.container_ip}:8480/metrics\""])
  #vm-select_list_for_metrics  = join(",", [for item in var.self_monitor_cluster_info.vm_select_list : "\"http://${item.container_ip}:8481/metrics\""])
  #grafana_list_for_metrics    = join(",", [for item in var.self_monitor_cluster_info.grafana_list : "\"http://${item.container_ip}:3000/metrics\""])
}

locals {
  #realtime_vm_storage_list_for_metrics = join(",", [for item in var.realtime_cluster_info.vm_storage_list : "\"http://${item.container_ip}:8482/metrics\""])
  #realtime_vm_insert_list_for_metrics  = join(",", [for item in var.realtime_cluster_info.vm_insert_list : "\"http://${item.container_ip}:8480/metrics\""])
  #realtime_vm_select_list_for_metrics  = join(",", [for item in var.realtime_cluster_info.vm_select_list : "\"http://${item.container_ip}:8481/metrics\""])
  realtime_grafana_list_for_metrics = join(",", [for item in var.realtime_cluster_info.grafana_list : "\"http://${item.container_ip}:3000/metrics\""])
}



resource "kubernetes_config_map" "self-monitor-cluster-vm-agent-file-sd" {
  metadata {
    name      = "self-monitor-cluster-vm-agent-file-sd"
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

locals {
  yaml_targets_for_self_monitor_vm_storage = join("\n", [
    for item in var.self_monitor_cluster_info.vm_storage_list :
    join("", [
      "- targets: [\"http://${item.container_ip}:8482/metrics\"]\n",
      "  labels:\n",
      "    \"from\": \"vm-agent\"\n",
      "    \"region\": \"${var.configs.region}\"\n",
      "    \"env\": \"${var.configs.env}\"\n",
      "    \"cluster\": \"self-monitor-cluster\"\n",
      "    \"role\": \"vm-storage\"\n",
      "    \"container_ip\": \"${item.container_ip}\"\n",
      "    \"container_name\": \"${item.container_name}\"\n"
    ])
  ])
  yaml_targets_for_self_monitor_vm_insert = join("\n", [
    for item in var.self_monitor_cluster_info.vm_insert_list :
    join("", [
      "- targets: [\"http://${item.container_ip}:8480/self-monitor-cluster-insert/metrics\"]\n",
      "  labels:\n",
      "    \"from\": \"vm-agent\"\n",
      "    \"region\": \"${var.configs.region}\"\n",
      "    \"env\": \"${var.configs.env}\"\n",
      "    \"cluster\": \"self-monitor-cluster\"\n",
      "    \"role\": \"vm-insert\"\n",
      "    \"container_ip\": \"${item.container_ip}\"\n",
      "    \"container_name\": \"${item.container_name}\"\n"
    ])
  ])
  yaml_targets_for_self_monitor_vm_select = join("\n", [
    for item in var.self_monitor_cluster_info.vm_select_list :
    join("", [
      "- targets: [\"http://${item.container_ip}:8481/self-monitor-cluster-select/metrics\"]\n",
      "  labels:\n",
      "    \"from\": \"vm-agent\"\n",
      "    \"region\": \"${var.configs.region}\"\n",
      "    \"env\": \"${var.configs.env}\"\n",
      "    \"cluster\": \"self-monitor-cluster\"\n",
      "    \"role\": \"vm-select\"\n",
      "    \"container_ip\": \"${item.container_ip}\"\n",
      "    \"container_name\": \"${item.container_name}\"\n"
    ])
  ])
  yaml_targets_for_realtime_grafana = join("\n", [
    for item in var.realtime_cluster_info.grafana_list :
    join("", [
      "- targets: [\"http://${item.container_ip}:3000/metrics\"]\n",
      "  labels:\n",
      "    \"from\": \"vm-agent\"\n",
      "    \"region\": \"${var.configs.region}\"\n",
      "    \"env\": \"${var.configs.env}\"\n",
      "    \"cluster\": \"realtime-cluster\"\n",
      "    \"role\": \"grafana\"\n",
      "    \"container_ip\": \"${item.container_ip}\"\n",
      "    \"container_name\": \"${item.container_name}\"\n"
    ])
  ])
  yaml_targets_for_alert_dingtalk_webhook = join("\n", [
    for item in var.alert_cluster_info.dingtalk_webhook_list :
    join("", [
      "- targets: [\"http://${item.container_ip}:8060/metrics\"]\n",
      "  labels:\n",
      "    \"from\": \"vm-agent\"\n",
      "    \"region\": \"${var.configs.region}\"\n",
      "    \"env\": \"${var.configs.env}\"\n",
      "    \"cluster\": \"alert-cluster\"\n",
      "    \"role\": \"dingtalk-webhook\"\n",
      "    \"container_ip\": \"${item.container_ip}\"\n",
      "    \"container_name\": \"${item.container_name}\"\n"
    ])
  ])
  yaml_targets_for_alert_alert_manager = join("\n", [
    for item in var.alert_cluster_info.alert_manager_list :
    join("", [
      "- targets: [\"http://${item.container_ip}:9093/metrics\"]\n",
      "  labels:\n",
      "    \"from\": \"vm-agent\"\n",
      "    \"region\": \"${var.configs.region}\"\n",
      "    \"env\": \"${var.configs.env}\"\n",
      "    \"cluster\": \"alert-cluster\"\n",
      "    \"role\": \"alert-manager\"\n",
      "    \"container_ip\": \"${item.container_ip}\"\n",
      "    \"container_name\": \"${item.container_name}\"\n"
    ])
  ])
}

resource "kubernetes_config_map" "self-monitor-cluster-vm-agent-exporters" {
  metadata {
    name      = "self-monitor-cluster-vm-agent-exporters"
    namespace = var.configs.namespace
  }

  data = {
    "exporters.yaml" = <<EOF
${local.yaml_targets_for_self_monitor_vm_storage}
${local.yaml_targets_for_self_monitor_vm_insert}
${local.yaml_targets_for_self_monitor_vm_select}

####################
${local.yaml_targets_for_realtime_grafana}
####################
${local.yaml_targets_for_alert_dingtalk_webhook}
${local.yaml_targets_for_alert_alert_manager}

    EOF
  }
}

resource "kubernetes_deployment" "self-monitor-cluster-vm-agent" {
  depends_on = [
    kubernetes_config_map.self-monitor-cluster-vm-agent-file-sd,
    kubernetes_config_map.self-monitor-cluster-vm-agent-exporters
  ]
  count = local.vm-agent-count

  metadata {
    namespace = var.configs.namespace
    name      = "${local.vm-agent-name}-${count.index}"
    labels = {
      kubernetes_deployment_name = local.vm-agent-name
      node_index                 = count.index
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        kubernetes_deployment_name = local.vm-agent-name
        node_index                 = count.index
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.vm-agent-name
          node_index                 = count.index
        }
      }

      spec {
        container {
          image             = "victoriametrics/vmagent:${var.configs.vm.version}"
          image_pull_policy = "IfNotPresent"
          args = [
            "-httpListenAddr=:8429",
            "-http.pathPrefix=/self-monitor-cluster-vm-agent/",
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
            "-pushmetrics.extraLabel=cluster=\"self-monitor-cluster\"",
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
            #"-remoteWrite.url=http://$${var.self_monitor_cluster_info.vm_insert_addr}/self-monitor-cluster-insert/insert/0/prometheus/api/v1/write",
            "-remoteWrite.url=http://self-monitor-cluster-vm-insert-service:8480/self-monitor-cluster-insert/insert/0/prometheus/api/v1/write",
            "-promscrape.config=/configs/file_sd_configs.yaml",
          ]
          name = "${local.vm-agent-name}-${count.index}"

          resources {
            limits = {
              cpu    = "2" #todo
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
            value = "2" #todo
          }
        } # end container

        volume {
          name = "file-sd-config-volume"

          config_map {
            name = "self-monitor-cluster-vm-agent-file-sd"
          }
        }

        volume {
          name = "exporters-config-volume"

          config_map {
            name = "self-monitor-cluster-vm-agent-exporters"
          }
        }
      }
    }
  }
}

data "external" "self-monitor-cluster-vm-agent-status" {
  depends_on = [kubernetes_deployment.self-monitor-cluster-vm-agent]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.vm-agent-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "self-monitor-cluster-vm-agent-containers" {
  value = [for item in jsondecode(data.external.self-monitor-cluster-vm-agent-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "self-monitor-cluster-vm-agent-service" {
  depends_on = [data.external.self-monitor-cluster-vm-agent-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.vm-agent-name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.vm-agent-name
    }

    port {
      protocol    = "TCP"
      port        = 8429
      target_port = 8429
    }

    type = "ClusterIP"
  }
}

output "self-monitor-cluster-vm-agent-service-addr" {
  value = "${kubernetes_service.self-monitor-cluster-vm-agent-service.spec.0.cluster_ip}:${kubernetes_service.self-monitor-cluster-vm-agent-service.spec.0.port.0.target_port}"
}
