把vm-restore, vm-storage 打包到同一个镜像文件，在容器内部实现切换历史数据的加载

1.先制作镜像

```
cd terraform/historical_cluster/docker_image
make docker-build && make docker-tag && make docker-push
```

2.确保每天都产生备份数据到 s3 上
3.部署历史节点对应的 vm-storage
  * 每天半夜一点会切换前一天的备份文件
  * 切换期间，同一个容器内会启动两个 vm-storage
  * 昨天的 vm-storage 启动成功后，前天的 vm-storage 会退出，并删除前天的数据文件夹
