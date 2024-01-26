locals {
  self-monitor-cluster-vm-alert-name = "self-monitor-cluster-vm-alert"
}

resource "kubernetes_deployment" "self-monitor-cluster-vm-alert" {
  count = 2 #todo
  depends_on = [
    kubernetes_deployment.alert-cluster-dingtalk-webhook,
    kubernetes_deployment.alert-cluster-alert-manager-main,
    kubernetes_deployment.alert-cluster-alert-manager-secondary
  ]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.self-monitor-cluster-vm-alert-name}-${count.index}"
  }

  spec {
    replicas = 1 # 当这里为 2 时，两个容器做同样的告警查询。通过冗余来解决单点问题，缺点是资源消耗高一倍

    selector {
      match_labels = {
        kubernetes_deployment_name = local.self-monitor-cluster-vm-alert-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.self-monitor-cluster-vm-alert-name
        }
      }

      spec {
        container {
          image             = "victoriametrics/vmalert:${var.configs.vm.version}"
          image_pull_policy = "IfNotPresent"
          args = [
            "-configCheckInterval=1m",
            "-datasource.queryStep=1m",
            "-datasource.queryTimeAlignment",
            "-datasource.roundDigits=2",
            "-datasource.showURL", # 便于排查问题
            #"-datasource.url=$${var.realtime_cluster_info.select_addr}",
            "-datasource.url=http://self-monitor-cluster-vm-select-service:8481/self-monitor-cluster-select/select/0/prometheus/",
            "-evaluationInterval=1m",
            "-external.label='from=\"self-monitor-cluster-vm-alert\"'",
            "-external.url=",
            "-httpListenAddr=:8880",
            "-http.pathPrefix=/self-monitor-cluster-vm-alert/",
            "-loggerDisableTimestamps",
            "-loggerFormat=${var.configs.log.format}",
            "-loggerLevel=${var.configs.log.level}",
            "-loggerOutput=${var.configs.log.output}",
            "-pushmetrics.extraLabel=region=\"${var.configs.region}\"",
            "-pushmetrics.extraLabel=env=\"${var.configs.env}\"",
            "-pushmetrics.extraLabel=cluster=\"self-monitor-cluster\"",
            "-pushmetrics.extraLabel=role=\"vm-alert\"",
            "-pushmetrics.extraLabel=container_ip=\"$(CONTAINER_IP)\"",
            "-pushmetrics.extraLabel=container_name=\"$(CONTAINER_NAME)\"",
            "-pushmetrics.interval=${var.push_metrics.interval}",
            "-pushmetrics.url=${var.push_metrics.addr}",
            "-memory.allowedPercent=80",
            "-notifier.showURL",
            #"-notifier.url=http://$${local.alert-manager-addr}", # alert manager, 可以配置多次
            "-notifier.url=http://alert-cluster-alert-manager-service:9093", # alert manager, 可以配置多次
            #remote read 用于读告警的状态
            "-remoteRead.lookback=1h",
            "-remoteRead.showURL",
            #"-remoteRead.url=http://$${var.realtime_cluster_info.select_addr}/select/0/prometheus/",
            "-remoteRead.url=http://self-monitor-cluster-vm-select-service:8481/self-monitor-cluster-select/select/0/prometheus/",
            # remote write  用于保存 recording rules 的结果
            "-remoteWrite.concurrency=2",
            "-remoteWrite.flushInterval=15s",
            "-remoteWrite.maxBatchSize=1000",
            "-remoteWrite.maxQueueSize=10000",
            "-remoteWrite.retryMaxTime=30s",
            "-remoteWrite.retryMinInterval=1s",
            "-remoteWrite.sendTimeout=30s",
            "-remoteWrite.showURL",
            #"-remoteWrite.url=http://$${var.realtime_cluster_info.insert_addr}/insert/0/prometheus/", # vm-insert
            "-remoteWrite.url=http://self-monitor-cluster-vm-insert-service:8480/self-monitor-cluster-insert/insert/0/prometheus/", # vm-insert
            #规则文件
            "-rule=/rules/rules.yaml"
          ]
          name = "${local.self-monitor-cluster-vm-alert-name}-${count.index}"

          resources {
            limits = {
              cpu    = "1" #todo
              memory = "2Gi"
            }
            requests = {
              cpu    = "0.1"
              memory = "256Mi"
            }
          }

          port {
            container_port = 8880
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
            name       = "alert-cluster-vm-alert-configs-volume"
            mount_path = "/rules/"
          }
        } # end container
        volume {
          name = "alert-cluster-vm-alert-configs-volume"

          config_map {
            name = "alert-cluster-vm-alert-configs-${count.index}"
          }
        }
      }
    }
  }
}

data "external" "self-monitor-cluster-vm-alert-status" {
  depends_on = [kubernetes_deployment.self-monitor-cluster-vm-alert]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.self-monitor-cluster-vm-alert-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "self-monitor-cluster-vm-alert-containers" {
  value = [for item in jsondecode(data.external.self-monitor-cluster-vm-alert-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "self-monitor-cluster-vm-alert-service" {
  depends_on = [data.external.self-monitor-cluster-vm-alert-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.self-monitor-cluster-vm-alert-name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.self-monitor-cluster-vm-alert-name
    }

    port {
      protocol    = "TCP"
      port        = 8880
      target_port = 8880
    }

    type = "ClusterIP"
  }
}

output "self-monitor-cluster-vm-alert-service-addr" {
  value = "${kubernetes_service.self-monitor-cluster-vm-alert-service.spec.0.cluster_ip}:${kubernetes_service.self-monitor-cluster-vm-alert-service.spec.0.port.0.target_port}"
}
