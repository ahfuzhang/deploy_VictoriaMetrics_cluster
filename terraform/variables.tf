
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
    dingtalk_webhooks = list(object({
      url    = string
      secret = string
    }))
    pvc = object({
      storage_class_name = string
      basepath           = string
    })
    realtime_cluster = object({
      domain             = string
      storage_node_count = number
      storage_path       = string
    })
    s3 = object({ # for backup data
      AWS_ACCESS_KEY_ID     = string
      AWS_SECRET_ACCESS_KEY = string
      AWS_REGION            = string
      AWS_BUCKET            = string
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
      version = "v1.96.0"
    }
    self_monitor_cluster_domain = ""
    dingtalk_webhooks           = []
    pvc = {
      storage_class_name = ""
      basepath           = "/vm-data/"
    }
    realtime_cluster = {
      domain             = ""
      storage_node_count = 3 #todo
      storage_path       = "/vm-data/realtime-cluster/sharding-"
    }
    s3 = {
      AWS_ACCESS_KEY_ID     = ""
      AWS_SECRET_ACCESS_KEY = ""
      AWS_REGION            = ""
      AWS_BUCKET            = ""
    }
  }
}
