VPP_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp-native/vpp/bin/vpp
VPPCTL_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp-native/vpp/bin/vppctl
TTS_TEMPLATE_VALUE=2

.PHONY: help

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  help 			- print this help"
	@echo "  install-deps 	- install dependencies"
	@echo "  network-setup 	- setup network"
	@echo "  network-clean 	- clean network"
	@echo "  connect_X 		- connect to VPP instance X"


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