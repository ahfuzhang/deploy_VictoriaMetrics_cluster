# How to use

## Prepare

0. Edit main.tf, ready `k8s.yaml` config file:

```
provider "kubernetes" {
  config_path = "./test/k8s.yaml"  # set right k8s config file
}
```

1. Create PVC
```shell
cd terraform/pvc
cat <<EOF > terraform.tfvars
configs = {
  namespace = "xxxx"  # set namespace
  pvc = {
    storage_class_name = "yyyy"  # set class name
  }
}
EOF
make init
make apply
```

**<font color="red">PVC should be created in a separate directory, so that PVC will not be destroyed when other resources are destroyed.
(Don’t ask me why I know that PVC cannot be destroyed together)</font>**


2. write a file `terraform.tfvars`

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
  dingtalk_webhooks = [{
    url    = "https://oapi.dingtalk.com/robot/send?access_token=${ding_talk_token}"
    secret = "${secret}"
  }]
  pvc = {
    storage_class_name = ""
    basepath           = "/vm-data/"
  }
  realtime_cluster = {
    domain             = "realtime-cluster.ahfu.com"
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
```

3. config `kubectl` command line

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

`sudo vi /etc/hosts`

Add:

```
self-monitor-cluster.my-own-test.com 10.151.0.70 # change the ip to ingress ip
realtime-cluster.my-own-test.com 10.151.0.71
```

Then add `Prometheus` data source by `realtime-cluster-vm-select-service` and `self-monitor-vm-select-service`:
```
# like this:
http://10.43.130.240:8481/select/0/prometheus/
```

Finally, you can use `MetricsQL` to query data on grafana.
