VPP_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp_debug-native/vpp/bin/vpp
VPPCTL_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp_debug-native/vpp/bin/vppctl
TTS_TEMPLATE_VALUE=2

.PHONY: help

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  help 			- print this help"
	@echo "  network-setup 	- setup network"
	@echo "  network-clean 	- clean network"

network-setup:
	@echo "Setting up network"
	@VPP_BINARY_PATH=$(VPP_BINARY_PATH) VPPCTL_BINARY_PATH=$(VPPCTL_BINARY_PATH) TTS_TEMPLATE_VALUE=$(TTS_TEMPLATE_VALUE) bash ./network/setup-network.sh

network-clean:
	@echo "Cleaning up network"	
	bash ./network/clean-network.sh

