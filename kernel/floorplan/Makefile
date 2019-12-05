#
# Copyright (c) 2019, Wuklab. All rights reserved.
#

# TODO: we should also autogenerate the top.v file
# so that the pr instaces inside match the RP regions we want to create.
# Ultimately, its top.v decide!
NR_GENERATED_HOOKS=4

GENERATED_MODULE_NAME=generated_rp_module
LOG=generated_vivado_log/vivado.log
JOURNAL=generated_vivado_log/vivado.journal
IP_REPO=../../generated_ip

all:
	mkdir -p generated_modules
	mkdir -p generated_vivado_log
	./prepare.sh 1 $(NR_GENERATED_HOOKS) $(GENERATED_MODULE_NAME)
	vivado -log $(LOG) -applog -journal $(JOURNAL)	\
	       -mode tcl -source run_vivado.tcl		\
	       -tclargs $(NR_GENERATED_HOOKS) $(GENERATED_MODULE_NAME) $(IP_REPO)

clean:
	rm -rf generated_*
	rm -rf hd_visual
	find ./ -name "generated_ip" | xargs rm -rf
	find ./ -name "generated_vivado_project" | xargs rm -rf
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf
	find ./ -name "awsver.txt" | xargs rm -rf
	find ./ -name "generated" | xargs rm -rf
	find ./ -name "generated_project" | xargs rm -rf
