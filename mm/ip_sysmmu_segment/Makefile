VIVADO = vivado
VIVADO_PRJ = generated_vivado_project/generated_vivado_project.xpr

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

all:
	$(VIVADO) -mode tcl -source run_vivado_$(TARGET_BOARD).tcl

g:
	$(VIVADO) $(VIVADO_PRJ)

clean:
	find ./ -name "generated_ip" | xargs rm -rf
	find ./ -name "generated_hls_project" | xargs rm -rf
	find ./ -name "generated_vivado_project" | xargs rm -rf
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf
