# How to use

## Prapare

1. write a file `terraform.tfvars`

```
configs = {
  namespace = "ahfu" # namespace on k8s
  region    = "HK"
  env       = "test"
  log = {
    format = "json"
    level  = "INFO"
    output = "stdout"
  }
  vm = {
    version = "v1.96.0"  # vectoria metrics version
  }
  self_monitor_cluster_domain = "self-monitor-cluster.my-own-test.com"
  realtime_cluster_domain     = "realtime-cluster.my-own-test.com"
  dingtalk_webhooks = [{
    url    = "https://oapi.dingtalk.com/robot/send?access_token=${ding_talk_token}"
    secret = "${secret}"
  }]
}
```

2. config `kubectl` command line

```
kubectl config use-context ahfu
```

## Deploy

```
make init
make apply
```

## View datas from grafana

Copy `realtime-cluster-ingress-ip` and `self-monitor-cluster-ingress-ip` from terraform outputs.

sudo vi /etc/hosts
Add:
```
self-monitor-cluster.my-own-test.com 10.151.0.70 # change the ip to ingress ip
realtime-cluster.my-own-test.com 10.151.0.71
```

Then add `Prometheus` data source by `realtime-cluster-vm-select-services` and `self-monitor-vm-select-services`:
```
# like this:
http://10.43.130.240:8481/select/0/prometheus/
```

Finally, you can use `MetricsQL` to query data on grafana.
