#
# Copyright (c) 2019, Wuklab, Purdue University.
#

GENERATED_IP = generated_ip/
GENERATED_VIVADO_PROJECT = generated_vivado_project/

all:
	mkdir -p $(GENERATED_IP)
	mkdir -p $(GENERATED_VIVADO_PROJECT)

clean:
	rm -rf $(GENERATED_IP)
	rm -rf $(GENERATED_VIVADO_PROJECT)

help:
	@echo "Hello"
