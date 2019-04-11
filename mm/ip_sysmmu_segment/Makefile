PROJ_DIR      = generated_vivado_project
TB_DIR        = generated_tb
PROJ_NAME     = generated_vivado_project.xpr
TB_PROJ_NAME  = mm_sys_mm.xpr
VIVADO_PRJ    = $(PROJ_DIR)/$(PROJ_NAME)
VIVADO_TB_PRJ = $(TB_DIR)/$(TB_PROJ_NAME)

VIVADO        = vivado

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

all: ip testbench
.PHONY: ip

simple_ip:
	$(VIVADO) -mode tcl -source run_vivado_$(TARGET_BOARD).tcl

ip:
	$(VIVADO) -mode tcl -source run_vivado_sysmmu_$(TARGET_BOARD).tcl

g:
	$(VIVADO) $(VIVADO_PRJ)

simple_testbench:
	$(VIVADO) -mode tcl -source run_vivado_$(TARGET_BOARD)_tb.tcl

testbench:
	$(VIVADO) -mode tcl -source run_vivado_sysmmu_$(TARGET_BOARD)_tb.tcl

gtb:
	$(VIVADO) $(VIVADO_TB_PRJ)

clean:
	rm -rf $(PROJ_DIR)
	rm -rf $(TB_DIR)
	find ./ -name "generated_ip" | xargs rm -rf
	find ./ -name "generated_tb" | xargs rm -rf
	find ./ -name "generated_hls_project" | xargs rm -rf
	find ./ -name "generated_vivado_project" | xargs rm -rf
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf

help:
	@echo "Help"
	@echo "  # make ip               <- make the sys memory management ip with axi wrapper, sys memory management unit (works for vcu108)"
	@echo "  # make testbench        <- Make a sub-unit testbench projects for 'ip' with axi traffic gen and memory interface and a dram model (works for vcu108)"
	@echo "  # make simple_ip        <- make the sys memory management ip with axi wrapper and simple translator (works for arty_a7)"
	@echo "  # make simple_testbench <- Make a sub-unit testbench projects for 'simple_ip' with axi traffic gen and memory interface and a dram model (works for arty_a7)"
	@echo "  # make all              <- make both the ip and the testbench"
	@echo "  # make g                <- Open GUI for the sys mm IP"
	@echo "  # make gtb              <- Open GUI for the sys mm sub-unit TB"

