
variable "configs" {
  type = object({
    namespace = string
    pvc = object({
      storage_class_name = string
    })
  })
  default = {
    namespace = "default"
    pvc = {
      storage_class_name = ""
    }
  }
}
