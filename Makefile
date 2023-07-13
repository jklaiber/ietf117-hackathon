VPP_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp_debug-native/vpp/bin/vpp
VPPCTL_BINARY_PATH=$(HOME)/vpp/build-root/build-vpp_debug-native/vpp/bin/vppctl

.PHONY: help

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  help 			- print this help"
	@echo "  network-setup 	- setup network"
	@echo "  network-clean 	- clean network"

network-setup:
	@echo "Setting up network"
	bash ./network/setup-network.sh

network-clean:
	@echo "Cleaning up network"	
	bash ./network/clean-network.sh

