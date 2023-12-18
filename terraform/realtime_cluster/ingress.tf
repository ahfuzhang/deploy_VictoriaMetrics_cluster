
locals {
  ingress-name = "realtime-cluster-ingress"
}

resource "kubernetes_ingress_v1" "realtime-cluster-ingress" {
  depends_on = [kubernetes_service.realtime-cluster-vm-select-services]
  metadata {
    name      = local.ingress-name
    namespace = var.configs.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = var.configs.realtime_cluster_domain
      http {
        path {
          backend {
            service {
              name = "realtime-cluster-grafana-services"
              port {
                number = 3000
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

data "external" "realtime-cluster-ingress-status" {
  depends_on = [kubernetes_ingress_v1.realtime-cluster-ingress]
  program    = ["bash", "-c", "kubectl get ingress ${local.ingress-name} -n ${var.configs.namespace} -o json | jq -c '{\"r\": .|tojson }'"]
}

output "realtime-cluster-ingress-ip" {
  value = [for item in jsondecode(data.external.realtime-cluster-ingress-status.result.r).status.loadBalancer.ingress : item.ip]
}
