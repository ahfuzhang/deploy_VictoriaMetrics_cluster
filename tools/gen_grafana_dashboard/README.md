A tool to use golang template to generate grafana dashboard JSON.

## How to use

`make build`

### example: To generate vm-select grafana dashboard
1. query `http://vm-select-addr/metrics`
2. save metrics data to `examples/metrics/vm-select.txt`
3. add a yaml config file `examples/configs/vm-select.yaml`
4. run command line:

```shell
./build/gen_grafana_dashboard  \
	    -target=./examples/generated/vm-select.json \
		-metric=./examples/metrics/vm-select.txt \
		-config=./examples/configs/vm-select.yaml \
		-template=templates/grafana.json_no_role.tpl
```

### command line:
* `-target=xxx.json`: generated file, must set.
* `-config=xxx.yaml`: a yaml config to show how to generate.must set.
* `-metric=xxx.txt`: add all metrics item from a metrics file. Optional.
* `-template=xxx.tpl`: a golang template file of grafana dashboard JSON.Optional.
