

locals {
  grafana-name   = "self-monitor-cluster-grafana"
  vm_select_addr = "${kubernetes_service.self-monitor-cluster-vm-select-services.spec.0.cluster_ip}:${kubernetes_service.self-monitor-cluster-vm-select-services.spec.0.port.0.target_port}"
}


resource "kubernetes_config_map" "self-monitor-cluster-grafana-config" {
  metadata {
    name      = "self-monitor-cluster-grafana-config"
    namespace = var.configs.namespace
  }

  data = {
    "grafana.ini" = <<EOF
[plugins]
allow_loading_unsigned_plugins = victoriametrics-datasource
	EOF
    "init.sh"     = <<EOF
if [ ! -d "/vm-data/self-moniotor-cluster/grafana/plugins/victoriametrics-datasource/" ]; then
    wget https://github.com/VictoriaMetrics/grafana-datasource/releases/download/v0.5.0/victoriametrics-datasource-v0.5.0.tar.gz
    mkdir -p /vm-data/self-moniotor-cluster/grafana/plugins/
    tar -zxf victoriametrics-datasource-v0.5.0.tar.gz -C /vm-data/self-moniotor-cluster/grafana/plugins/
fi
mkdir -p /vm-data/self-moniotor-cluster/grafana/provisioning/datasources/
cp /vm-data/self-moniotor-cluster/grafana/config/victoriametrics-datasource.yaml /vm-data/self-moniotor-cluster/grafana/provisioning/datasources/
EOF

    "victoriametrics-datasource.yaml" = <<EOF
    apiVersion: 1

    # List of data sources to insert/update depending on what's
    # available in the database.
    datasources:
       # <string, required> Name of the VictoriaMetrics datasource
       # displayed in Grafana panels and queries.
       - name: VictoriaMetrics
          # <string, required> Sets the data source type.
         type: victoriametrics-datasource
          # <string, required> Sets the access mode, either
          # proxy or direct (Server or Browser in the UI).
          # Some data sources are incompatible with any setting
          # but proxy (Server).
         access: direct
         # <string> Sets default URL of the single node version of VictoriaMetrics
         url: http://${local.vm_select_addr}/select/0/prometheus/
         # <string> Sets the pre-selected datasource for new panels.
         # You can set only one default data source per organization.
         isDefault: true

    EOF
  }
}

resource "kubernetes_deployment" "self-monitor-cluster-grafana" {

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
          working_dir = "/"
          args = [
            "-x",
            "/vm-data/self-moniotor-cluster/grafana/config/init.sh"
          ]
          volume_mount {
            name       = "self-monitor-cluster-pvc"
            mount_path = "/vm-data/self-moniotor-cluster/grafana/"
            read_only  = false
          }
          volume_mount {
            name       = "grafana-config-volume"
            mount_path = "/vm-data/self-moniotor-cluster/grafana/config/"
            read_only  = false
          }
        }


        container {
          image             = "grafana/grafana:10.2.2"
          image_pull_policy = "IfNotPresent"
          name              = local.grafana-name

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
            name       = "self-monitor-cluster-pvc"
            mount_path = "/vm-data/self-moniotor-cluster/grafana/"
          }
          volume_mount {
            name       = "grafana-config-volume"
            mount_path = "/vm-data/self-moniotor-cluster/grafana/config/"
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
            value = "/vm-data/self-moniotor-cluster/grafana/data/"
          }
          env {
            name  = "GF_PATHS_PLUGINS"
            value = "/vm-data/self-moniotor-cluster/grafana/plugins/"
          }
          env {
            name  = "GF_PATHS_PROVISIONING" # GF_PATHS_PROVISIONING=/etc/grafana/provisioning
            value = "/vm-data/self-moniotor-cluster/grafana/provisioning/"
          }
          # env {
          #   name  = "GF_PATHS_HOME"
          #   value = "/vm-data/self-moniotor-cluster/grafana/home/"
          # }
          # env {
          #   name  = "GF_SERVER_ROOT_URL"
          #   value = "http://${var.configs.domain}/self-monitor-cluster-grafana/"
          # }
          env {
            name  = "GF_PATHS_CONFIG"
            value = "/vm-data/self-moniotor-cluster/grafana/config/grafana.ini"
          }
        } # end container

        volume {
          name = "self-monitor-cluster-pvc"

          persistent_volume_claim {
            claim_name = "self-monitor-cluster-pvc"
          }
        }
        volume {
          name = "grafana-config-volume"

          config_map {
            name = "self-monitor-cluster-grafana-config"
          }
        }
      }
    }
  }
}

data "external" "self-monitor-cluster-grafana-status" {
  depends_on = [kubernetes_deployment.self-monitor-cluster-grafana]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.grafana-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "self-monitor-cluster-grafana-containers" {
  value = [for item in jsondecode(data.external.self-monitor-cluster-grafana-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}

resource "kubernetes_service" "self-monitor-cluster-grafana-services" {
  depends_on = [data.external.self-monitor-cluster-grafana-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.grafana-name}-services"
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

output "self-monitor-cluster-grafana-services-addr" {
  value = "${kubernetes_service.self-monitor-cluster-grafana-services.spec.0.cluster_ip}:${kubernetes_service.self-monitor-cluster-grafana-services.spec.0.port.0.target_port}"
}
