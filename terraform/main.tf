provider "kubernetes" {
  config_path = "./test/k8s.yaml"
}

module "self-monitor-cluster" {
  source  = "./self_monitor_cluster/"
  configs = var.configs
}

locals {
  push_metrics = {
    interval = "15s"
    addr     = "http://${module.self-monitor-cluster.self-monitor-cluster-vm-insert-services-addr}/insert/0/prometheus/api/v1/import/prometheus"
  }
}

module "realtime-cluster" {
  source       = "./realtime_cluster/"
  configs      = var.configs
  push_metrics = local.push_metrics
}

locals {
  realtime_cluster_info = {
    select_addr     = "http://${module.realtime-cluster.realtime-cluster-vm-select-services-addr}/select/0/prometheus/"
    insert_addr     = module.realtime-cluster.realtime-cluster-vm-insert-services-addr
    vm_storage_list = module.realtime-cluster.realtime-cluster-vm-storage-containers
    vm_select_list  = module.realtime-cluster.realtime-cluster-vm-select-containers
    vm_insert_list  = module.realtime-cluster.realtime-cluster-vm-insert-containers
    grafana_list    = module.realtime-cluster.realtime-cluster-grafana-containers
  }
}

module "alert-cluster" {
  source                = "./alert_cluster/"
  configs               = var.configs
  push_metrics          = local.push_metrics
  realtime_cluster_info = local.realtime_cluster_info
}

module "metrics-data-source-cluster" {
  source                = "./metrics_data_source_cluster/"
  configs               = var.configs
  push_metrics          = local.push_metrics
  realtime_cluster_info = local.realtime_cluster_info
  self_monitor_cluster_info = {
    vm_storage_list = module.self-monitor-cluster.self-monitor-cluster-vm-storage-containers
    vm_select_list  = module.self-monitor-cluster.self-monitor-cluster-vm-select-containers
    vm_insert_list  = module.self-monitor-cluster.self-monitor-cluster-vm-insert-containers
    grafana_list    = module.self-monitor-cluster.self-monitor-cluster-grafana-containers
    vm_select_addr  = module.self-monitor-cluster.self-monitor-cluster-vm-select-services-addr
    vm_insert_addr  = module.self-monitor-cluster.self-monitor-cluster-vm-insert-services-addr
    grafana_addr    = module.self-monitor-cluster.self-monitor-cluster-grafana-services-addr
  }
  alert_cluster_info = {
    dingtalk_webhook_list = module.alert-cluster.alert-cluster-dingtalk-webhook-containers
    alert_manager_list    = module.alert-cluster.alert-cluster-alert-manager-containers
    vm_alert_list         = module.alert-cluster.alert-cluster-vm-alert-containers
  }
}

module "historical-cluster" {
  source                = "./historical_cluster/"
  configs               = var.configs
  push_metrics          = local.push_metrics
  realtime_cluster_info = local.realtime_cluster_info
}

//-----------------------------------------------------------------------------
output "self-monitor-vm-storage" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-storage-containers
}

output "self-monitor-vm-insert" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-insert-containers
}

output "self-monitor-vm-select" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-select-containers
}

output "self-monitor-grafana" {
  value = module.self-monitor-cluster.self-monitor-cluster-grafana-containers
}

output "self-monitor-vm-insert-services" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-insert-services-addr
}

output "self-monitor-vm-select-services" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-select-services-addr
}

output "self-monitor-grafana-services" {
  value = module.self-monitor-cluster.self-monitor-cluster-grafana-services-addr
}

output "self-monitor-cluster-ingress-ip" {
  value = module.self-monitor-cluster.self-monitor-cluster-ingress-ip
}

//-----------------------------------------------------------------------------
output "real-vm-storage" {
  value = module.realtime-cluster.realtime-cluster-vm-storage-containers
}

output "realtime-cluster-vm-insert" {
  value = module.realtime-cluster.realtime-cluster-vm-insert-containers
}

output "realtime-cluster-vm-select" {
  value = module.realtime-cluster.realtime-cluster-vm-select-containers
}

output "realtime-cluster-grafana" {
  value = module.realtime-cluster.realtime-cluster-grafana-containers
}

output "realtime-cluster-vm-insert-services" {
  value = module.realtime-cluster.realtime-cluster-vm-insert-services-addr
}

output "realtime-cluster-vm-select-services" {
  value = module.realtime-cluster.realtime-cluster-vm-select-services-addr
}

output "realtime-cluster-grafana-services" {
  value = module.realtime-cluster.realtime-cluster-grafana-services-addr
}

output "realtime-cluster-ingress-ip" {
  value = module.realtime-cluster.realtime-cluster-ingress-ip
}
//-----------------------------------------------------------------------------
output "alert-cluster-dingtalk-webhook-service" {
  value = module.alert-cluster.alert-cluster-dingtalk-webhook-service-addr
}

output "alert-cluster-alert-manager-service" {
  value = module.alert-cluster.alert-cluster-alert-manager-service-addr
}

output "alert-cluster-vm-alert" {
  value = module.alert-cluster.alert-cluster-vm-alert-containers
}
//-----------------------------------------------------------------------------
output "self-monitor-vm-agent" {
  value = module.metrics-data-source-cluster.self-monitor-cluster-vm-agent-containers
}

output "metrics-data-source-cluster-vm-agent" {
  value = module.metrics-data-source-cluster.metrics-data-source-cluster-vm-agent-containers
}
//-----------------------------------------------------------------------------
output "historical-cluster-vm-select-services" {
  value = module.historical-cluster.historical-cluster-vm-select-services-addr
}
