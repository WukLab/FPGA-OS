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

clean:
	rm -rf $(GENERATED_IP)

help:
	@echo "Hello"
