#
# Copyright (c) 2019, Wuklab, Purdue University.
#

GENERATED_IP = generated_ip/

#
# Order matters. Build small, no-dependency IPs first.
# System-level IPs must come at last.
#
all:
	mkdir -p $(GENERATED_IP)
	$(Q)make -C alloc
	$(Q)make -C net
	$(Q)make -C mm
	$(Q)make -C app
	$(Q)make -C system

#
# This cleans up everything.
# Compiling takes time.
# Use with caution.
#
clean:
	find ./ -name "generated_ip" | xargs rm -rf
	find ./ -name "generated_hls_project" | xargs rm -rf
	find ./ -name "generated_vivado_project" | xargs rm -rf
	find ./ -name "ipshared" | xargs rm -rf
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf
	find ./ -name "generated" | xargs rm -rf
	find ./ -name "generated_project" | xargs rm -rf

help:
	@echo "Hello"
