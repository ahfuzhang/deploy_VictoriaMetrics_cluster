
init:
	go mod init gen_grafana_dashboard

.PHONY: build

build: ./build/gen_grafana_dashboard
	@echo "ok"

./build/gen_grafana_dashboard: main.go
	go build -o build/gen_grafana_dashboard

.PHONY: all

all: build vm-agent vm-storage vm-select vm-insert vm-alert alert-manager
	@echo "ok"

vm-agent:
	./build/gen_grafana_dashboard  \
	    -target=./examples/generated/vm-agent.json \
		-metric=./examples/metrics/vm-agent.txt \
		-config=./examples/configs/vm-agent.yaml \
		-template=templates/grafana.json_no_role.tpl

vm-storage:
	./build/gen_grafana_dashboard  \
	    -target=./examples/generated/vm-storage.json \
		-metric=./examples/metrics/vm-storage.txt \
		-config=./examples/configs/vm-storage.yaml \
		-template=templates/grafana.json_no_role.tpl

vm-select:
	./build/gen_grafana_dashboard  \
	    -target=./examples/generated/vm-select.json \
		-metric=./examples/metrics/vm-select.txt \
		-config=./examples/configs/vm-select.yaml \
		-template=templates/grafana.json_no_role.tpl

vm-insert:
	./build/gen_grafana_dashboard  \
	    -target=./examples/generated/vm-insert.json \
		-metric=./examples/metrics/vm-insert.txt \
		-config=./examples/configs/vm-insert.yaml \
		-template=templates/grafana.json_no_role.tpl

vm-alert:
	./build/gen_grafana_dashboard  \
	    -target=./examples/generated/vm-alert.json \
		-metric=./examples/metrics/vm-alert.txt \
		-config=./examples/configs/vm-alert.yaml \
		-template=templates/grafana.json_no_role.tpl

alert-manager:
	./build/gen_grafana_dashboard  \
	    -target=./examples/generated/alert-manager.json \
		-metric=./examples/metrics/alert-manager.txt \
		-config=./examples/configs/alert-manager.yaml \
		-template=templates/grafana.json_no_role.tpl
