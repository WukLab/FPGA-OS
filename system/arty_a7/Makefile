VIVADO = vivado
VIVADO_PRJ = generated_vivado_project/generated_vivado_project.xpr

all:
	$(Q)make -C legacy_hls
	$(VIVADO) -mode tcl -source run_vivado.tcl

g:
	$(VIVADO) $(VIVADO_PRJ)
