VPP_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp-native/vpp/bin/vpp
VPPCTL_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp-native/vpp/bin/vppctl
TTS_TEMPLATE_VALUE=2
GOVPP_PATH=$(HOME)/govpp
GOVPP_INPUT_FILES=$(HOME)/vpp/build-root/install-vpp-native/vpp/share/vpp/api/core/sr_pt.api.json
GOVPP_INPUT_DIR=$(HOME)/vpp/build-root/install-vpp-native/vpp/share/vpp/api
GOVPP_OUTPUT_DIR=$(HOME)/govpp/binapi

.PHONY: help

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  help 			- print this help"
	@echo "  install-deps 		- install dependencies"
	@echo "  network-setup 	- setup network"
	@echo "  network-clean 	- clean network"
	@echo "  connect_X 		- connect to VPP instance X"
	@echo "  generate-api-files 	- generate API files"
	@echo "  build-apitest 	- build apitest"
	@echo "  run-apitest 		- run apitest"


install-deps:
	@echo "Installing dependencies"
	@sudo apt-get install -y net-tools bridge-utils 

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
	go run main.go --input-file=$(GOVPP_INPUT_FILES) --output-dir=$(GOVPP_OUTPUT_DIR) --input-dir=$(GOVPP_INPUT_DIR)

build-apitest:
	@echo "Building apitest"
	cd $(GOVPP_PATH)/pt && go build -o ./pt pt.go

run-apitest:
	@echo "Running apitest"
	sudo $(GOVPP_PATH)/pt/pt