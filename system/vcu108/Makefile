VIVADO = vivado
VIVADO_PRJ = generated_vivado_project/generated_vivado_project.xpr

all:
	$(VIVADO) -mode tcl -source run_vivado.tcl

clean:
	find ./ -name "generated_vivado_project" | xargs rm -rf
	find ./ -name "ipshared" | xargs rm -rf
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf

g:
	$(VIVADO) $(VIVADO_PRJ)
