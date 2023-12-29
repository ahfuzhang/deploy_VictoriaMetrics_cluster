#!/bin/sh

# variables:
# configs_namespace
# configs_region
# configs_env
# configs_log_format
# configs_log_level
# configs_log_output
# configs_vm_version
# count_index
# storage_base_path = /vm-data/historical-cluster/
# s3_storage_base_path = /metrics/vmstorage-backup/realtime-cluster/daily/
# push_metrics_addr
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_REGION
# AWS_BUCKET
# CONTAINER_IP
# CONTAINER_NAME
# n_days_before = 1  # from n before days to start load snapshot

# restore download from s3
function restore() {
	local v_date_str=$1
	/vmrestore-prod \
	    "-concurrency=1" \
        "-maxBytesPerSecond=1GB" \
        "-memory.allowedPercent=80" \
        "-src=s3://${AWS_BUCKET}${s3_storage_base_path}${v_date_str}/sharding-${count_index}/" \
        "-storageDataPath=${storage_base_path}${v_date_str}/sharding-${count_index}/" \
		"-loggerDisableTimestamps" \
		"-loggerFormat=${configs_log_format}" \
		"-loggerLevel=${configs_log_level}" \
		"-loggerOutput=${configs_log_output}" \
		"-pushmetrics.extraLabel=region=\"${configs_region}\"" \
		"-pushmetrics.extraLabel=env=\"${configs_env}\"" \
		"-pushmetrics.extraLabel=cluster=\"historical-cluster\"" \
		"-pushmetrics.extraLabel=role=\"vm-restore-daily\"" \
		"-pushmetrics.extraLabel=container_ip=\"${CONTAINER_IP}\"" \
		"-pushmetrics.extraLabel=container_name=\"${CONTAINER_NAME}\"" \
		"-pushmetrics.interval=2s" \
		"-pushmetrics.url=${push_metrics_addr}"
		#"-skipBackupCompleteCheck"
	local v_exit_code=$?
	echo "vm-backup exit code: ${v_exit_code}"
	if [ "${v_exit_code}" -ne 0 ]; then
		sleep 60
		exit -1
	fi
}

# vmstorage start vm-storage
function vmstorage() {
	local v_date_str=$1
	local v_http_port=$2  # 8482
	local v_insert_port=$3  #8400
	local v_select_port=$4  #8401
	/vmstorage-prod \
		"-blockcache.missesBeforeCaching=2" \
		"-cacheExpireDuration=30m" \
		"-dedup.minScrapeInterval=15s" \
		"-denyQueriesOutsideRetention" \
		"-finalMergeDelay=60s" \
		"-httpListenAddr=:${v_http_port}" \
		"-insert.maxQueueDuration=1m" \
		"-maxConcurrentInserts=1" \
		"-memory.allowedPercent=80" \
		"-retentionPeriod=10y" \
		"-search.maxConcurrentRequests=32" \
		"-search.maxUniqueTimeseries=1000000" \
		"-snapshotsMaxAge=1d" \
		"-storage.cacheSizeIndexDBDataBlocks=0" \
		"-storage.cacheSizeIndexDBIndexBlocks=0" \
		"-storage.cacheSizeIndexDBTagFilters=0" \
		"-storage.cacheSizeStorageTSID=0" \
		"-storage.maxDailySeries=100000000" \
		"-storage.maxHourlySeries=50000000" \
		"-storage.minFreeDiskSpaceBytes=1GB" \
		"-storageDataPath=${storage_base_path}${v_date_str}/sharding-${count_index}/" \
		"-vminsertAddr=:${v_insert_port}" \
		"-vmselectAddr=:${v_select_port}" \
		"-loggerDisableTimestamps" \
		"-loggerFormat=${configs_log_format}" \
		"-loggerLevel=${configs_log_level}" \
		"-loggerOutput=${configs_log_output}" \
		"-pushmetrics.extraLabel=region=\"${configs_region}\"" \
		"-pushmetrics.extraLabel=env=\"${configs_env}\"" \
		"-pushmetrics.extraLabel=cluster=\"historical-cluster\"" \
		"-pushmetrics.extraLabel=role=\"vm-storage\"" \
		"-pushmetrics.extraLabel=container_ip=\"${CONTAINER_IP}\"" \
		"-pushmetrics.extraLabel=container_name=\"${CONTAINER_NAME}\"" \
		"-pushmetrics.interval=2s" \
		"-pushmetrics.url=${push_metrics_addr}"
	local v_exit_code=$?
	echo "vm-storage exit code: ${v_exit_code}"
	if [ "${v_exit_code}" -ne 0 ]; then
		sleep 60  # when at first time, download again
		exit -1
	fi
}

v_port_rotate=0

# rotate load yesterday's data and kill the day before yesterday
function rotate(){
	local v_date_str=$1
	local v_old_pid=$(pidof "vmstorage-prod")
	# get backup file
	local v_storage_path="${storage_base_path}${v_date_str}/sharding-${count_index}/"
	if [ -d "${v_storage_path}" ]; then
        return 1
	fi
	restore "${v_date_str}"
	if [ "${v_port_rotate}" -eq 1 ]; then
		v_port_rotate=0
		vmstorage "${v_date_str}" 8482 8400 8401 &
	else
		v_port_rotate=1
		vmstorage "${v_date_str}" 18482 18400 18401 &
	fi
	sleep 10
	kill -15 ${v_old_pid}
	while true; do
		if kill -0 ${v_old_pid} > /dev/null 2>&1; then
			echo "PID ${v_old_pid} is running."
			sleep 1
		else
			break
		fi
	done
	#
	local v_old_storage_path="${storage_base_path}$(get_n_days_before $((n_days_before+1)))/sharding-${count_index}/"
	rm -fr "${v_old_storage_path}"
}

# run_server_forever
function run_server_forever(){
	local v_old_pastday_str=$1
	sleep $(get_timespan_of_tomorrow_1_clock)
	while true; do
		#
		local v_pastday_str=$(get_n_days_before "${n_days_before}")
		#
		if [[ "$v_old_pastday_str" != "$v_pastday_str" ]]; then
			# another day
			v_old_pastday_str="${v_pastday_str}"
			rotate $v_old_pastday_str
		fi
		sleep $(get_timespan_of_tomorrow_1_clock)  #todo: this cause container can not delete soon
	done
}

# on_start when first time start
function on_start() {
	# at first time
	local v_date_str=$1
	local v_storage_path="${storage_base_path}${v_date_str}/sharding-${count_index}/"
	if [ -d "${v_storage_path}" ]; then
	  return 0
	fi
	# download from s3
	restore "${v_date_str}"
}

function get_n_days_before(){
	local n=$1
	local timestamp=$(date -u +"%s")
	local before_days=$((timestamp - 86400*n))
	local date_str=$(date -u -d @"$before_days" +"%Y-%m-%d")
	echo $date_str
}

function get_timespan_of_tomorrow_1_clock(){
	local timestamp=$(date -u +"%s")
	local v_timespan=$(( (86400 - timestamp%86400)+3600 ))
	echo "${v_timespan}s"
}

function main() {
	local date_str=$(get_n_days_before "${n_days_before}")
	on_start "${date_str}"
	vmstorage "${date_str}" 8482 8400 8401
	#
	run_server_forever "${date_str}"
}

main
