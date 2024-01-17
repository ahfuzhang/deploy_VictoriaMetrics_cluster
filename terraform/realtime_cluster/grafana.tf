

locals {
  grafana-name   = "realtime-cluster-grafana"
  vm_select_addr = "${kubernetes_service.realtime-cluster-vm-select-service.spec.0.cluster_ip}:${kubernetes_service.realtime-cluster-vm-select-service.spec.0.port.0.target_port}"
}


resource "kubernetes_config_map" "realtime-cluster-grafana-config" {
  metadata {
    name      = "realtime-cluster-grafana-config"
    namespace = var.configs.namespace
  }

  data = {
    "grafana.ini" = <<EOF
[plugins]
allow_loading_unsigned_plugins = victoriametrics-datasource
	EOF
    "init.sh"     = <<EOF
if [ ! -d "/vm-data/grafana/plugins/victoriametrics-datasource/" ]; then
    wget https://github.com/VictoriaMetrics/grafana-datasource/releases/download/v0.5.0/victoriametrics-datasource-v0.5.0.tar.gz
    mkdir -p /vm-data/grafana/plugins/
    tar -zxf victoriametrics-datasource-v0.5.0.tar.gz -C /vm-data/grafana/plugins/
fi
mkdir -p /vm-data/grafana/provisioning/datasources/ /vm-data/grafana/config/ /vm-data/grafana/data/ /vm-data/grafana/plugins/
cp /grafana/config/datasource.yaml /vm-data/grafana/provisioning/datasources/
cp /grafana/config/grafana.ini /vm-data/grafana/config/
#echo "1" > /vm-data/grafana/data/test.txt
chmod -R 777 /vm-data/grafana/

#sleep 10

EOF

    "datasource.yaml" = <<EOF
apiVersion: 1

# List of data sources to insert/update depending on what's
# available in the database.
datasources:
    - name: Prometheus-realtime-cluster
      type: prometheus
      access: direct
      #orgId: 1
      url: http://${local.vm_select_addr}/select/0/prometheus/
      #url: http://realtime-cluster-vm-select-service:8481/select/0/prometheus/
      isDefault: false
      version: 1
      editable: true

    - name: Prometheus-self-monitor-cluster
      type: prometheus
      access: direct
      #orgId: 1
      url: http://${var.self_monitor_cluster_info.vm_select_addr}/self-monitor-cluster-select/select/0/prometheus/
      #url: http://self-monitor-cluster-vm-select-service:8481/self-monitor-cluster-select/select/0/prometheus/
      isDefault: false
      version: 1
      editable: true

    # <string, required> Name of the VictoriaMetrics datasource
    # displayed in Grafana panels and queries.
    - name: VictoriaMetrics-realtime-cluster
      # <string, required> Sets the data source type.
      type: victoriametrics-datasource
      # <string, required> Sets the access mode, either
      # proxy or direct (Server or Browser in the UI).
      # Some data sources are incompatible with any setting
      # but proxy (Server).
      access: proxy
      # <string> Sets default URL of the single node version of VictoriaMetrics
      #url: http://realtime-cluster-vm-select-service:8481/select/0/prometheus/
      url: http://${local.vm_select_addr}/select/0/prometheus/
      # <string> Sets the pre-selected datasource for new panels.
      # You can set only one default data source per organization.
      isDefault: false
      editable: true

    - name: VictoriaMetrics-self-monitor-cluster
      # <string, required> Sets the data source type.
      type: victoriametrics-datasource
      # <string, required> Sets the access mode, either
      # proxy or direct (Server or Browser in the UI).
      # Some data sources are incompatible with any setting
      # but proxy (Server).
      access: proxy
      # <string> Sets default URL of the single node version of VictoriaMetrics
      #url: http://self-monitor-cluster-vm-select-service:8481/self-monitor-cluster-select/select/0/prometheus/
      url: http://${var.self_monitor_cluster_info.vm_select_addr}/self-monitor-cluster-select/select/0/prometheus/
      # <string> Sets the pre-selected datasource for new panels.
      # You can set only one default data source per organization.
      isDefault: false
      editable: true

    EOF
  }
}

resource "kubernetes_deployment" "realtime-cluster-grafana" {
  depends_on = [
    kubernetes_config_map.realtime-cluster-grafana-config,
    kubernetes_service.realtime-cluster-vm-select-service
  ]
  metadata {
    namespace = var.configs.namespace
    name      = local.grafana-name
    labels = {
      kubernetes_deployment_name = local.grafana-name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        kubernetes_deployment_name = local.grafana-name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.grafana-name
        }
      }

      spec {
        init_container {
          image             = "alpine:3.18.4"
          image_pull_policy = "IfNotPresent"
          name              = "${local.grafana-name}-init"
          command           = ["/bin/sh"]
          working_dir       = "/"
          args = [
            "-x",
            "/grafana/config/init.sh"
          ]
          volume_mount {
            name       = "realtime-cluster-pvc"
            mount_path = "/vm-data/"
            read_only  = false
          }
          volume_mount {
            name       = "grafana-config-volume"
            mount_path = "/grafana/config/"
            read_only  = false
          }
        }


        container {
          image             = "grafana/grafana:10.2.2"
          image_pull_policy = "IfNotPresent"
          name              = local.grafana-name
          #command           = ["/bin/sh", "-c", "echo 123;sleep 20;"]

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

          port {
            container_port = 3000
          }

          volume_mount {
            name       = "realtime-cluster-pvc"
            mount_path = "/vm-data/"
            read_only  = false
          }
          # volume_mount {
          #   name       = "grafana-config-volume"
          #   mount_path = "/vm-data/grafana/config/"
          # }
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
            value = "1"
          }

          # env {
          #   name  = "GF_SECURITY_ADMIN_USER"
          #   value = "admin"
          # }
          # env {
          #   name  = "GF_SECURITY_ADMIN_PASSWORD"
          #   value = "admin"  #todo:
          # }
          env {
            name  = "GF_PATHS_DATA"
            value = "/vm-data/grafana/data/"
          }
          env {
            name  = "GF_PATHS_PLUGINS"
            value = "/vm-data/grafana/plugins/"
          }
          env {
            name  = "GF_PATHS_PROVISIONING" # GF_PATHS_PROVISIONING=/etc/grafana/provisioning
            value = "/vm-data/grafana/provisioning/"
          }
          # env {
          #   name  = "GF_PATHS_HOME"
          #   value = "/vm-data/grafana/home/"
          # }
          # env {
          #   name  = "GF_SERVER_ROOT_URL"
          #   value = "http://${var.configs.domain}/realtime-cluster-grafana/"
          # }
          env {
            name  = "GF_PATHS_CONFIG"
            value = "/vm-data/grafana/config/grafana.ini"
          }
        } # end container

        volume {
          name = "realtime-cluster-pvc"

          persistent_volume_claim {
            claim_name = "realtime-cluster-pvc"
          }
        }
        volume {
          name = "grafana-config-volume"

          config_map {
            name = "realtime-cluster-grafana-config"
          }
        }
      }
    }
  }
}

data "external" "realtime-cluster-grafana-status" {
  depends_on = [kubernetes_deployment.realtime-cluster-grafana]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.grafana-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "realtime-cluster-grafana-containers" {
  value = [for item in jsondecode(data.external.realtime-cluster-grafana-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "realtime-cluster-grafana-service" {
  depends_on = [data.external.realtime-cluster-grafana-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.grafana-name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.grafana-name
    }

    port {
      protocol    = "TCP"
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

output "realtime-cluster-grafana-service-addr" {
  value = "${kubernetes_service.realtime-cluster-grafana-service.spec.0.cluster_ip}:${kubernetes_service.realtime-cluster-grafana-service.spec.0.port.0.target_port}"
}
