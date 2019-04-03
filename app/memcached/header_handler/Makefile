VIVADO_DIR = generated_vivado_project
VIVADO_PRJ = $(VIVADO_DIR)/generated_vivado_project.xpr

VIVADO_HLS = vivado_hls
VIVADO     = vivado

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

.DEFAULT_GOAL := all

.PHONY: all

all:
	$(VIVADO) -mode tcl -source run_vivado_$(TARGET_BOARD).tcl

g:
	$(VIVADO) $(VIVADO_PRJ)

clean:
	rm -rf $(VIVADO_DIR)
	find . -name "*_prj" -type d | xargs rm -rf
	find . -name "*_project" -type d | xargs rm -rf
	find . -name "vivado*.jou" -type f | xargs rm -rf
	find . -name "vivado*.log" -type f | xargs rm -rf


help:
	@echo "Help"
	@echo "  # make all	<- generate vivado project for header striping logic" 
	@echo "  # make g	<- Open GUI for the header_striping block"
