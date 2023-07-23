VPP_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp-native/vpp/bin/vpp
VPPCTL_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp-native/vpp/bin/vppctl
TTS_TEMPLATE_VALUE=2
GOVPP_PATH=$(HOME)/govpp
GOVPP_INPUT_FILES=$(HOME)/vpp/build-root/install-vpp-native/vpp/share/vpp/api/core/sr_pt.api.json
GOVPP_INPUT_DIR=$(HOME)/vpp/build-root/install-vpp-native/vpp/share/vpp/api
GOVPP_OUTPUT_DIR=$(HOME)/govpp/binapi
PT_PROBECOLLECTOR_PATH=$(HOME)/probe-collector/bin/
PT_PROBEGEN_PATH=./bins/ptprobegen
PT_PROBEGEN_CLIENT_PATH=./bins/ptprobegen-client
ANALYZER_CONFIG_PATH=$(HOME)/ietf117-hackathon/analyzers

.PHONY: help

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  help 			- print this help"
	@echo "  install-deps 		- install dependencies"
	@echo "  network-setup 		- setup network"
	@echo "  network-clean 		- clean network"
	@echo "  connect_<node> 		- connect to VPP CLI"
	@echo "  generate-api-files 	- generate API files"
	@echo "  build-apitest 		- build apitest"
	@echo "  run-apitest 		- run apitest"
	@echo "  start-collector 		- start collector"
	@echo "  stop-collector 		- stop collector"
	@echo "  start-probing 		- start probing"
	@echo "  stop-probing 		- stop probing"
	@echo "  generate-analyzer-topo 	- generate analyzer topology"
	@echo "  start-analyzers 		- start analyzers"
	@echo "  stop-analyzers 		- stop analyzers"
	@echo "  start-aggregator 		- start aggregator"
	@echo "  stop-aggregator 		- stop aggregator"
	@echo "  start-pipeline 		- start pipeline"
	@echo "  stop-pipeline 		- stop pipeline"
	@echo "  set-delay 		- set delay on interface 22"
	@echo "  delete-delay 		- delete delay on interface 22"


install-deps:
	@echo "Installing dependencies"
	@sudo apt-get install -y net-tools bridge-utils jq

network-setup:
	@VPP_BINARY_PATH=$(VPP_BINARY_PATH) VPPCTL_BINARY_PATH=$(VPPCTL_BINARY_PATH) TTS_TEMPLATE_VALUE=$(TTS_TEMPLATE_VALUE) bash ./network/setup-network.sh

network-clean:
	@bash ./network/clean-network.sh

connect_%:
	@echo "Connecting to VPP CLI"
	@sudo $(VPPCTL_BINARY_PATH) -s /run/vpp/cli.vpp$*.sock*

generate-api-files:
	@echo "Generating API files"
	cd ../govpp/cmd/binapi-generator && \
	go run main.go --input=$(GOVPP_INPUT_DIR) --output-dir=$(GOVPP_OUTPUT_DIR)

build-apitest:
	@echo "Building apitest"
	cd $(GOVPP_PATH)/pt && go build -o ./pt pt.go

run-apitest:
	@echo "Running apitest"
	sudo $(GOVPP_PATH)/pt/pt

start-collector:
	@echo "Starting collector"
	sudo $(PT_PROBECOLLECTOR_PATH)/probe-collector --port collector --kafka 172.16.16.28:9093 &

stop-collector:
	@echo "Stopping collector"
	sudo pkill -f probe-collector

start-probing:
	@echo "Starting probing"
	@PT_PROBEGEN_PATH=$(PT_PROBEGEN_PATH) PT_PROBEGEN_CLIENT_PATH=$(PT_PROBEGEN_CLIENT_PATH) bash ./probing/start-probing.sh

stop-probing:
	@echo "Stopping probing"
	sudo pkill -f ptprobegen
	sudo pkill -f ptprobegen-client

generate-analyzer-topo:
	@echo "Generating analyzer topology"
	cd $(HOME)/analyzers && \
	python3 edges_colored_dict_builder.py --color-file=$(ANALYZER_CONFIG_PATH)/node-config.yml --topo-file=$(ANALYZER_CONFIG_PATH)/topology.yml --out-file=$(ANALYZER_CONFIG_PATH)/edges-colored-dict.yml

start-analyzers:
	@echo "Starting analyzers"
	@ANALYZER_CONFIG_PATH=$(ANALYZER_CONFIG_PATH) bash ./analyzers/start-analyzers.sh

stop-analyzers:
	@echo "Stopping analyzers"
	sudo pkill -f python3

start-aggregator:
	@echo "Starting aggregator"
	$(HOME)/pt-analyzer/binaries/probe-aggregator --influxdb-org=pathtracing --influxdb-token=$(shell docker exec influxdb influx auth list --json | jq -r .[].token) --kafka-server=172.16.16.28:9093 &

stop-aggregator:
	@echo "Stopping aggregator"
	sudo pkill -f probe-aggregator

start-pipeline: start-collector start-aggregator start-analyzers

stop-pipeline: stop-analyzers stop-aggregator stop-collector

set-delay:
	@echo "Setting delay on interface 22"
	sudo tc qdisc add dev tap4 root netem delay 10ms

delete-delay:
	@echo "Deleting delay on interface 22"
	sudo tc qdisc del dev tap4 root netem