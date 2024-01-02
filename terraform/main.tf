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
    #addr     = "http://${module.self-monitor-cluster.self-monitor-cluster-vm-insert-service-addr}/self-monitor-cluster-insert/insert/0/prometheus/api/v1/import/prometheus"
    addr = "http://self-monitor-cluster-vm-insert-service:8480/self-monitor-cluster-insert/insert/0/prometheus/api/v1/import/prometheus"
  }
  self_monitor_cluster_info = {
    vm_storage_list = module.self-monitor-cluster.self-monitor-cluster-vm-storage-containers  # for vm-agent
    vm_select_list  = module.self-monitor-cluster.self-monitor-cluster-vm-select-containers   # for vm-agent
    vm_insert_list  = module.self-monitor-cluster.self-monitor-cluster-vm-insert-containers   # for vm-agent
    vm_select_addr  = module.self-monitor-cluster.self-monitor-cluster-vm-select-service-addr # use in grafana
    #vm_insert_addr  = module.self-monitor-cluster.self-monitor-cluster-vm-insert-service-addr # use service name
  }
}

module "realtime-cluster" {
  source                    = "./realtime_cluster/"
  configs                   = var.configs
  push_metrics              = local.push_metrics
  self_monitor_cluster_info = local.self_monitor_cluster_info
}

locals {
  realtime_cluster_info = {
    #select_addr     = "http://${module.realtime-cluster.realtime-cluster-vm-select-service-addr}/select/0/prometheus/"
    insert_addr     = module.realtime-cluster.realtime-cluster-vm-insert-service-addr
    vm_storage_list = module.realtime-cluster.realtime-cluster-vm-storage-containers
    vm_select_list  = module.realtime-cluster.realtime-cluster-vm-select-containers
    vm_insert_list  = module.realtime-cluster.realtime-cluster-vm-insert-containers
    grafana_list    = module.realtime-cluster.realtime-cluster-grafana-containers
  }
}

module "alert-cluster" {
  source       = "./alert_cluster/"
  configs      = var.configs
  push_metrics = local.push_metrics
  #realtime_cluster_info = local.realtime_cluster_info
  #self_monitor_cluster_info = local.self_monitor_cluster_info
}

module "metrics-data-source-cluster" {
  source                    = "./metrics_data_source_cluster/"
  configs                   = var.configs
  push_metrics              = local.push_metrics
  realtime_cluster_info     = local.realtime_cluster_info
  self_monitor_cluster_info = local.self_monitor_cluster_info
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

output "self-monitor-vm-insert-service" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-insert-service-addr
}

output "self-monitor-vm-select-service" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-select-service-addr
}

output "self-monitor-cluster-ingress-ip" {
  value = module.self-monitor-cluster.self-monitor-cluster-ingress-ip
}

output "self-monitor-vm-storage-service-list-for-insert" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-storage-service-list-for-insert
}

output "self-monitor-vm-storage-service-list-for-select" {
  value = module.self-monitor-cluster.self-monitor-cluster-vm-storage-service-list-for-select
}

//-----------------------------------------------------------------------------
output "realtime-cluster-vm-storage" {
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

output "realtime-cluster-vm-insert-service" {
  value = module.realtime-cluster.realtime-cluster-vm-insert-service-addr
}

output "realtime-cluster-vm-select-service" {
  value = module.realtime-cluster.realtime-cluster-vm-select-service-addr
}

output "realtime-cluster-grafana-service" {
  value = module.realtime-cluster.realtime-cluster-grafana-service-addr
}

output "realtime-cluster-ingress-ip" {
  value = module.realtime-cluster.realtime-cluster-ingress-ip
}

output "realtime-cluster-vm-storage-service-list-for-insert" {
  value = module.realtime-cluster.realtime-cluster-vm-storage-service-list-for-insert
}

output "realtime-cluster-vm-storage-service-list-for-select" {
  value = module.realtime-cluster.realtime-cluster-vm-storage-service-list-for-select
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

output "alert-cluster-vm-alert-service" {
  value = module.alert-cluster.alert-cluster-vm-alert-service-addr
}

output "self-monitor-cluster-vm-alert" {
  value = module.alert-cluster.self-monitor-cluster-vm-alert-containers
}

output "self-monitor-cluster-vm-alert-service" {
  value = module.alert-cluster.self-monitor-cluster-vm-alert-service-addr
}
//-----------------------------------------------------------------------------
output "self-monitor-vm-agent" {
  value = module.metrics-data-source-cluster.self-monitor-cluster-vm-agent-containers
}

output "self-monitor-vm-agent-service" {
  value = module.metrics-data-source-cluster.self-monitor-cluster-vm-agent-service-addr
}

output "metrics-data-source-cluster-vm-agent" {
  value = module.metrics-data-source-cluster.metrics-data-source-cluster-vm-agent-containers
}

output "metrics-data-source-cluster-vm-agent-service" {
  value = module.metrics-data-source-cluster.metrics-data-source-cluster-vm-agent-service-addr
}
//-----------------------------------------------------------------------------
output "historical-cluster-vm-select-service" {
  value = module.historical-cluster.historical-cluster-vm-select-service-addr
}

output "historical-cluster-vm-storage" {
  value = module.historical-cluster.historical-cluster-vm-storage-containers
}
