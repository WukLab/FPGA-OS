VIVADO         = vivado
VIVADO_PRJ_DIR = generated_vivado_project
VIVADO_PRJ     = $(VIVADO_PROJ_DIR)/generated_vivado_project.xpr

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = arty_a7
endif

all:
	$(VIVADO) -mode tcl -source run_vivado_$(TARGET_BOARD).tcl

g:
	$(VIVADO) $(VIVADO_PRJ)

clean:
	rm -rf $(VIVADO_PRJ_DIR)
	rm vivado*
