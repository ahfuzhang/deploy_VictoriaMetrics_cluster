
deploy:
	@echo "deploy"

.PHONY: self-monitor-cluster

self-monitor-cluster:
	mkdir -p self_monitor_cluster/data/grafana ; \
	docker-compose --file=self_monitor_cluster/docker-compose.yaml up -d
