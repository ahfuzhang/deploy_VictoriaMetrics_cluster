
locals {
  ingress-name = "self-monitor-cluster-ingress"
}

resource "kubernetes_ingress_v1" "self-monitor-cluster-ingress" {
  depends_on = [kubernetes_service.self-monitor-cluster-nginx-service]
  metadata {
    name      = local.ingress-name
    namespace = var.configs.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = var.configs.self_monitor_cluster_domain
      http {
        path {
          backend {
            service {
              name = "self-monitor-cluster-nginx-service"
              port {
                number = 80
              }
            }
          }
          path      = "/"
          path_type = "ImplementationSpecific"
        }
      }
    }
  }
}

data "external" "self-monitor-cluster-ingress-status" {
  depends_on = [kubernetes_ingress_v1.self-monitor-cluster-ingress]
  program    = ["bash", "-c", "kubectl get ingress ${local.ingress-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "self-monitor-cluster-ingress-ip" {
  value = [for item in jsondecode(data.external.self-monitor-cluster-ingress-status.result.r).status.loadBalancer.ingress : item.ip]
}
