

resource "kubernetes_persistent_volume_claim" "realtime-cluster-pvc" {
  metadata {
    name      = "realtime-cluster-pvc"
    namespace = var.configs.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "2048Gi" #todo
      }
    }
    storage_class_name = var.configs.pvc.storage_class_name
  }
}
