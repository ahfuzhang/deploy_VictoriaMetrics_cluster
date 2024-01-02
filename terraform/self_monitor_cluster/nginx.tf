# use this to debug
# delete this file on release env

locals {
  nginx_name = "self-monitor-cluster-nginx"
}

locals {
  # cur_cluster = "self-monitor-cluster"
  # cur_role    = "vm_select"
  # nginx_conf_vm_select = join("\n", [
  #   for index, item in jsondecode(data.external.self-monitor-cluster-vm-select-status.result.r).items :
  #   join("\n", [
  #     "        location /metrics/${local.cur_cluster}/${var.configs.region}/${var.configs.env}/${local.cur_role}/${index}/ {",
  #     "           proxy_pass http://${item.status.podIP}:8481/metrics;",
  #     "        }",
  #   ])
  # ])
  # nginx_conf_vm_insert = join("\n", [
  #   for index, item in jsondecode(data.external.self-monitor-cluster-vm-insert-status.result.r).items :
  #   join("\n", [
  #     "        location /metrics/${local.cur_cluster}/${var.configs.region}/${var.configs.env}/vm-insert/${index}/ {",
  #     "           proxy_pass http://${item.status.podIP}:8480/metrics;",
  #     "        }",
  #   ])
  # ])



  #   nginx_conf_vm_select_for_query = join("\n", [
  #     for index, item in jsondecode(data.external.self-monitor-cluster-vm-select-status.result.r).items :
  #     join("\n", [
  #       "        location /metrics/${local.cur_cluster}/${var.configs.region}/${var.configs.env}/${local.cur_role}/${index}/ {",
  #       "           proxy_pass http://${item.status.podIP}:8481/metrics;",
  #       "        }",
  #     ])
  #   ])
}

resource "kubernetes_config_map" "self-monitor-cluster-nginx-config" {
  metadata {
    name      = "${local.nginx_name}-config"
    namespace = var.configs.namespace
  }

  data = {
    "nginx.conf" = <<EOF

user nginx;
worker_processes 1;
error_log /dev/stdout debug;
pid /var/run/nginx.pid;
events {
    worker_connections 20;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    charset utf-8;

    access_log  /dev/stdout;
    sendfile        on;
    tcp_nopush     on;
    keepalive_timeout  65;
    gzip  on;

    server {
        listen 80;
        #server_name example.com; # 替换为您的域名或IP地址

        location / {
            root /homepage/; # 您的静态文件目录
            index index.html index.htm;
            autoindex on; # 启用目录浏览
            autoindex_exact_size off; # 显示文件大小（开/关）
            autoindex_localtime off; # 显示文件的本地时间（开/关）
            sendfile on;
        }
        location /self-monitor-cluster-pvc/ {
            root /; # 您的静态文件目录
            #index index.html index.htm;
            autoindex on; # 启用目录浏览
            autoindex_exact_size on; # 显示文件大小（开/关）
            autoindex_localtime on; # 显示文件的本地时间（开/关）
            sendfile on;
        }
        location /realtime-cluster-pvc/ {
            root /; # 您的静态文件目录
            #index index.html index.htm;
            autoindex on; # 启用目录浏览
            autoindex_exact_size on; # 显示文件大小（开/关）
            autoindex_localtime on; # 显示文件的本地时间（开/关）
            sendfile on;
        }

        # realtime-cluster
        location /select/ {
           proxy_pass http://realtime-cluster-vm-select-service:8481;
        }
        location /insert/ {
           proxy_pass http://realtime-cluster-vm-insert-service:8480;
        }

        # alert-cluster
        location /alert-manager/ {
           rewrite ^/alert-manager/(.*)$ /$1 break;
           proxy_pass http://alert-cluster-alert-manager-service:9093;
        }
        location /alert-cluster-vm-alert/ {
          #rewrite ^/alert-cluster-vm-alert/(.*)$ /$1 break;
          proxy_pass http://alert-cluster-vm-alert-service:8880;
        }

        # self-monitor-cluster
        location /self-monitor-cluster-select/ {
           proxy_pass http://self-monitor-cluster-vm-select-service:8481;
        }
        location /self-monitor-cluster-insert/ {
           proxy_pass http://self-monitor-cluster-vm-insert-service:8480;
        }
        location /self-monitor-cluster-vm-agent/ {
           proxy_pass http://self-monitor-cluster-vm-agent-service:8429;
        }
        location /self-monitor-cluster-vm-alert/ {
          proxy_pass http://self-monitor-cluster-vm-alert-service:8880;
        }

        # metrics-data-source-cluster
        location /metrics-data-source-cluster-vm-agent/ {
           proxy_pass http://metrics-data-source-cluster-vm-agent-service:8429;
        }

        # historical cluster
        location /historical-cluster-select/ {
           proxy_pass http://historical-cluster-vm-select-service:8481;
        }

        #any addr
        location ~ ^/addr/(\d+\.\d+\.\d+\.\d+:\d+)/(.*)$ {
           proxy_pass http://$1/$2;
        }
    }
}

EOF
  }
}

resource "kubernetes_config_map" "self-monitor-cluster-nginx-index-page" {
  metadata {
    name      = "${local.nginx_name}-index-page"
    namespace = var.configs.namespace
  }

  data = {
    "index.html" = <<EOF
<html>
<head>
<title>Victoria Metrics cluster</title>
</head>
<body>
<h1>Victoria Metrics cluster</h1>
<hr/>

<!--________________________________________________________________________-->
<h2>self-monitor-cluster</h2>

<ul>

<li>
Metrics:
  <ul>
    <li><a href="/self-monitor-cluster-insert/metrics" target="_blank">/self-monitor-cluster-insert/metrics</a></li>
    <li><a href="/self-monitor-cluster-insert/select" target="_blank">/self-monitor-cluster-select/metrics</a></li>
  </ul>
</li>

<li>
Roles:
  <ul>
    <li><a href="/self-monitor-cluster-insert/" target="_blank">/self-monitor-cluster-insert/</a></li>
    <li> vm-select:
      <ul>
        <li>
          <a href="/self-monitor-cluster-select/" target="_blank">/self-monitor-cluster-select/</a>
        </li>
        <li>
          <a href="/self-monitor-cluster-select/select/0/vmui/" target="_blank">/self-monitor-cluster-select/select/0/vmui/</a>
        </li>
      </ul>
    </li>
    <li> vm-agent:
      <ul>
        <li>
          <a href="/self-monitor-cluster-vm-agent/" target="_blank">/self-monitor-cluster-vm-agent/</a>
        </li>
        <li>
          <a href="/self-monitor-cluster-vm-agent/targets" target="_blank">/self-monitor-cluster-vm-agent/targets</a>
        </li>
      </ul>
    </li>
    <li> vm-alert:
      <ul>
        <li>
          <a href="/self-monitor-cluster-vm-alert/" target="_blank">/self-monitor-cluster-vm-alert/</a>
        </li>
      </ul>
    </li>
  </ul>
</li>

</ul>
<!--________________________________________________________________________-->
<h2>metrics-data-source-cluster</h2>
<ul>

<li>
Roles:
  <ul>
    <li>metrics-data-source-cluster vm-agent:
      <ul>
        <li>
          <a href="/metrics-data-source-cluster-vm-agent/" target="_blank">/metrics-data-source-cluster-vm-agent/</a>
        </li>
        <li>
          <a href="/metrics-data-source-cluster-vm-agent/targets" target="_blank">/metrics-data-source-cluster-vm-agent/targets</a>
        </li>
      </ul>
    </li>
  </ul>
</li>

</ul>

<!--________________________________________________________________________-->
<h2>alert-cluster</h2>
<ul>

<li>
Roles:
  <ul>
    <li> vm-alert:
      <ul>
        <li>
          <a href="/alert-cluster-vm-alert/" target="_blank">/alert-cluster-vm-alert/</a>
        </li>
      </ul>
    </li>

    <li> alert-manager:
      <ul>
        <li>
          <a href="/alert-manager/" target="_blank">/alert-manager/</a>
        </li>
      </ul>
    </li>
  </ul>
</li>

</ul>
<!--________________________________________________________________________-->
<h2>realtime-cluster</h2>
<ul>

<li>
Roles:
  <ul>
    <li> vm-select:
      <ul>
        <li>
          <a href="/select/0/vmui/" target="_blank">/select/0/vmui/</a>
        </li>
      </ul>
    </li>
  </ul>
</li>

</ul>

<h2>historical-cluster</h2>
<ul>

<li>
Roles:
  <ul>
    <li> vm-select:
      <ul>
        <li>
          <a href="/historical-cluster-select/select/0/vmui/" target="_blank">/historical-cluster-select/select/0/vmui/</a>
        </li>
      </ul>
    </li>
  </ul>
</li>

</ul>
<!--________________________________________________________________________-->
<h2>pvc</h2>
<ul>

<li>realtime-cluster:
  <ul>
    <li> /vm-data/:
      <ul>
        <li>
          <a href="/realtime-cluster-pvc/" target="_blank">/realtime-cluster-pvc/</a>
        </li>
      </ul>
    </li>
  </ul>
</li>

<li>self-monitor-cluster:
  <ul>
    <li> /vm-data/:
      <ul>
        <li>
          <a href="/self-monitor-cluster-pvc/" target="_blank">/self-monitor-cluster-pvc/</a>
        </li>
      </ul>
    </li>
  </ul>
</li>

</ul>

</body>
</html>
EOF
  }
}


resource "kubernetes_deployment" "self-monitor-cluster-nginx" {
  depends_on = [
    kubernetes_config_map.self-monitor-cluster-nginx-config,
    kubernetes_config_map.self-monitor-cluster-nginx-index-page
  ]
  metadata {
    name      = local.nginx_name
    namespace = var.configs.namespace
    labels = {
      kubernetes_deployment_name = local.nginx_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        kubernetes_deployment_name = local.nginx_name
      }
    }

    template {
      metadata {
        labels = {
          kubernetes_deployment_name = local.nginx_name
        }
      }

      spec {
        container {
          image             = "nginx:1.25.3"
          image_pull_policy = "IfNotPresent"
          name              = local.nginx_name
          # command           = ["nginx-debug"]
          # args = [
          #   "-g",
          #   "'daemon off'"
          # ]

          port {
            container_port = 80
          }
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
            name = "nginx-config-volume"
            #mount_path = "/configs/"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }
          volume_mount {
            name       = "nginx-index-page-volume"
            mount_path = "/homepage/"
            #sub_path   = "nginx.conf"
          }
          volume_mount {
            name       = "self-monitor-cluster-pvc"
            mount_path = "/self-monitor-cluster-pvc/"
          }
          volume_mount {
            name       = "realtime-cluster-pvc"
            mount_path = "/realtime-cluster-pvc/"
          }

        }
        volume {
          name = "nginx-config-volume"

          config_map {
            name = "self-monitor-cluster-nginx-config"
          }
        }
        volume {
          name = "nginx-index-page-volume"

          config_map {
            name = "self-monitor-cluster-nginx-index-page"
          }
        }
        volume {
          name = "self-monitor-cluster-pvc"
          persistent_volume_claim {
            claim_name = "self-monitor-cluster-pvc"
          }
        }
        volume {
          name = "realtime-cluster-pvc"
          persistent_volume_claim {
            claim_name = "realtime-cluster-pvc"
          }
        }
      } #end spec
    }
  }
}

# resource "kubernetes_service" "self-monitor-cluster-nginx-service" {
#   metadata {
#     name      = "${local.nginx_name}-service"
#     namespace = var.configs.namespace
#   }

#   spec {
#     selector = {
#       app = local.nginx_name
#     }

#     port {
#       port        = 80
#       target_port = 80
#     }

#     type = "LoadBalancer"
#   }
# }

data "external" "self-monitor-cluster-nginx-status" {
  depends_on = [kubernetes_deployment.self-monitor-cluster-nginx]
  program    = ["bash", "-c", "kubectl get pods -l kubernetes_deployment_name=${local.nginx_name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "self-monitor-cluster-nginx-containers" {
  value = [for item in jsondecode(data.external.self-monitor-cluster-nginx-status.result.r).items : { container_name = item.metadata.name, container_ip = item.status.podIP }]
}


resource "kubernetes_service" "self-monitor-cluster-nginx-service" {
  depends_on = [data.external.self-monitor-cluster-nginx-status]
  metadata {
    namespace = var.configs.namespace
    name      = "${local.nginx_name}-service"
  }

  spec {
    selector = {
      kubernetes_deployment_name = local.nginx_name
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

output "self-monitor-cluster-nginx-service-addr" {
  value = "${kubernetes_service.self-monitor-cluster-nginx-service.spec.0.cluster_ip}:${kubernetes_service.self-monitor-cluster-nginx-service.spec.0.port.0.target_port}"
}
