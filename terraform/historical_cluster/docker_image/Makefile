
docker-build:
	docker build -t vm-historical:v1.95.1 --pull=false --platform=linux/amd64 -f Dockerfile .

docker-tag:
	docker tag vm-historical:v1.95.1 docker.io/ahfuzhang/vm-historical:v1.95.1

docker-push:
	docker push docker.io/ahfuzhang/vm-historical:v1.95.1

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
	  -e push_metrics_addr= \
	  -e CONTAINER_IP=127.0.0.1 \
	  -e CONTAINER_NAME=xxxx \
	  -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	  -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	  -e AWS_REGION=ap-southeast-1 \
	  -e AWS_BUCKET=s3-backup-bucket \
	  -e n_days_before=1 \
	  -v ./data:/vm-data/ \
	  vm-historical:v1.95.1 \
	  /bin/sh -x /daily.sh
