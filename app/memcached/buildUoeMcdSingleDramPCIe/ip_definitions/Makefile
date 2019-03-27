VIV_PRJ_PATH = generated_vivado_project
VIVADO_PRJ   = generated_vivado_project/pcie_mem_alloc.xpr

VIVADO     = vivado

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

.DEFAULT_GOAL := all

all: pcie_prj

pcie_prj:
	$(VIVADO) -mode tcl -source run_vivado.tcl

g:
	$(VIVADO) $(VIVADO_PRJ)

clean:
	rm -rf $(VIV_PRJ_PATH)
	find . -name "vivado*.jou" -type f | xargs rm -rf
	find . -name "vivado*.log" -type f | xargs rm -rf
	find . -name "vivado*" -type f | xargs rm -rf

help:
	@echo "Help"
	@echo "  # make pcie_prj <- generate vivado prj for the pcie top"
	@echo "  # make g        <- Open GUI for pcie_mem alloc ip"
