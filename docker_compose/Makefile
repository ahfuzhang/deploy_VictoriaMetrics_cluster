
.PHONY: deploy self-monitor-cluster realtime-cluster alert-cluster


deploy: self-monitor-cluster realtime-cluster alert-cluster historical-cluster
	@echo "deploy"

self-monitor-cluster:
	mkdir -p self_monitor_cluster/data/grafana ; \
	docker-compose --file=self_monitor_cluster/docker-compose.yaml up -d

realtime-cluster:
	mkdir -p realtime_cluster/data/grafana ; \
	docker-compose --file=realtime_cluster/docker-compose.yaml up -d

alert-cluster:
	docker-compose --file=alert_cluster/docker-compose.yaml up -d

historical-cluster:
	mkdir -p historical_cluster/data/ ; \
	docker-compose --file=historical_cluster/docker-compose.yaml up -d

backup:
	docker-compose --file=historical_cluster/backup/docker-compose.yaml up && \
	docker-compose --file=historical_cluster/backup/docker-compose.yaml down

restore:
	mkdir -p historical_cluster/data/ ; \
	docker-compose --file=historical_cluster/restore/docker-compose.yaml up && \
	docker-compose --file=historical_cluster/restore/docker-compose.yaml down

# for test
create_s3_dir:
	echo "" > 1.txt ; \
	aws s3 cp 1.txt s3://${AWS_BUCKET}/metrics/vmstorage/backup/2023-12-04/sharding-00/ ; \
	rm -f 1.txt
