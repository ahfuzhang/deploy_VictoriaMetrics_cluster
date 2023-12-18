
variable "configs" {
  type = object({
    namespace = string
    region    = string
    env       = string
    log = object({
      format = string
      level  = string
      output = string
    })
    vm = object({
      version = string
    })
    self_monitor_cluster_domain = string
    realtime_cluster_domain     = string
    dingtalk_webhooks = list(object({
      url    = string
      secret = string
    }))
    pvc = object({
      storage_class_name = string
    })
  })
  default = {
    namespace = "default"
    region    = "local"
    env       = "test"
    log = {
      format = "json"
      level  = "INFO"
      output = "stdout"
    }
    vm = {
      version = "v1.95.1"
    }
    self_monitor_cluster_domain = ""
    realtime_cluster_domain     = ""
    dingtalk_webhooks           = []
    pvc = {
      storage_class_name = ""
    }
  }
}
