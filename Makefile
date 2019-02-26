#
# Copyright (c) 2019, Wuklab, Purdue University.
#

GENERATED_IP = generated_ip/

all:
	mkdir -p $(GENERATED_IP)
	$(Q)make -C app
	$(Q)make -C net 
	$(Q)make -C mm

clean:
	rm -rf $(GENERATED_IP)

help:
	@echo "Hello"
