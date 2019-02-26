VIVADO = $(shell grep alias\ vivado= ~/.bashrc | awk -F"'" '{print $$2}')

all:
	$(VIVADO) -mode tcl -source run_vivado_arty_a7.tcl
g:
	$(VIVADO) generated_vivado_project/generated_vivado_project.xpr
