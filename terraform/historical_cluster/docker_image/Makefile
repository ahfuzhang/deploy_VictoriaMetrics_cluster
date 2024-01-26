
docker-build:
	docker build -t vm-historical:v1.95.1 --pull=false --platform=linux/amd64 -f Dockerfile .

docker-tag:
	docker tag vm-historical:v1.95.1 docker.io/ahfuzhang/vm-historical:v1.95.1

docker-push:
	docker push docker.io/ahfuzhang/vm-historical:v1.95.1

docker-build-with-vmfile:
	cp ../../../../VictoriaMetrics_cluster_v1.96.0/bin/vmfile_linux_amd64 ./bin/vmfile_linux_amd64 && \
	docker build -t vm-historical:v1.95.1-vmfile --pull=false --platform=linux/amd64 -f Dockerfile_with_vmfile .

docker-tag-with-vmfile:
	docker tag vm-historical:v1.95.1-vmfile docker.io/ahfuzhang/vm-historical:v1.95.1-vmfile

docker-push-with-vmfile:
	docker push docker.io/ahfuzhang/vm-historical:v1.95.1-vmfile

# for local test
docker-run:
	docker run -ti --rm --name vm-historical \
	  -p 8482:8482 \
	  -p 8400:8400 \
	  -p 8401:8401 \
	  -p 18482:18482 \
	  -p 18400:18400 \
	  -p 18401:18401 \
	  --cpus=0.5 \
	  -m=256m \
	  -e configs_namespace=default \
	  -e configs_region=HK \
	  -e configs_env=test \
	  -e configs_log_format=json \
	  -e configs_log_level=INFO \
	  -e configs_log_output=stdout \
	  -e configs_vm_version=v1.95.1 \
	  -e count_index=0 \
	  -e storage_base_path=/vm-data/historical-cluster/ \
	  -e s3_storage_base_path=/metrics/vmstorage-backup/realtime-cluster/daily/ \
	  -e push_metrics_addr=http://host.docker.internal:8480/self-monitor-cluster-insert/insert/0/prometheus/api/v1/import/prometheus \
	  -e CONTAINER_IP=127.0.0.1 \
	  -e CONTAINER_NAME=xxxx \
	  -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	  -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	  -e AWS_REGION=$(AWS_REGION) \
	  -e AWS_BUCKET=$(AWS_BUCKET) \
	  -e n_days_before=3 \
	  -e debug=1 \
	  -v ./data:/vm-data/ \
	  vm-historical:v1.95.1 \
	  /bin/sh /daily.sh

docker-run-vmfile:
	docker run -ti --rm --name vm-historical-vmfile \
	  -p 8482:8482 \
	  -p 8400:8400 \
	  -p 8401:8401 \
	  -p 18482:18482 \
	  -p 18400:18400 \
	  -p 18401:18401 \
	  --cpus=0.5 \
	  -m=256m \
	  -e configs_namespace=default \
	  -e configs_region=HK \
	  -e configs_env=test \
	  -e configs_log_format=json \
	  -e configs_log_level=INFO \
	  -e configs_log_output=stdout \
	  -e configs_vm_version=v1.95.1 \
	  -e sharding_prefix=sharding- \
	  -e sharding_count=3 \
	  -e dedup_minScrapeInterval=15s \
	  -e storage_base_path=/vm-data/historical-cluster/after_merge/ \
	  -e s3_storage_base_path=/metrics/vmstorage-backup/realtime-cluster/daily/ \
	  -e push_metrics_addr=http://host.docker.internal:8480/self-monitor-cluster-insert/insert/0/prometheus/api/v1/import/prometheus \
	  -e CONTAINER_IP=127.0.0.1 \
	  -e CONTAINER_NAME=xxxx \
	  -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	  -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	  -e AWS_REGION=$(AWS_REGION) \
	  -e AWS_BUCKET=$(AWS_BUCKET) \
	  -e n_days_before=4 \
	  -e debug=1 \
	  -v ./data:/vm-data/ \
	  vm-historical:v1.95.1-vmfile \
	  /bin/sh /daily_with_vmfile.sh
