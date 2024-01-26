

resource "kubernetes_persistent_volume_claim" "self-monitor-cluster-pvc" {
  metadata {
    name      = "self-monitor-cluster-pvc"
    namespace = var.configs.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "10Gi" #todo: change it when deploy
      }
    }
    storage_class_name = var.configs.pvc.storage_class_name
  }
}
