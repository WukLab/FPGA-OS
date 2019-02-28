VIVADO = vivado
VIVADO_PRJ = generated_vivado_project/mm_sys_mm.xpr

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = arty_a7
endif

all:
	$(VIVADO) -mode tcl -source run_vivado_$(TARGET_BOARD).tcl

g:
	$(VIVADO) $(VIVADO_PRJ)
