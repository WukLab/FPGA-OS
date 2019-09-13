VIVADO        = vivado

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu118
endif

all:
	@echo -e '\033[31m**'
	@echo    '**'
	@echo    '**  Notice'
	@echo    '**  Make sure you have built mm/mapping/'
	@echo    '**'
	@echo -e '**\033[0m'
	@sleep 2
	$(Q)./generate_hls.sh $(TARGET_BOARD)
	$(VIVADO) -mode tcl -source run_vivado_$(TARGET_BOARD).tcl

g:
	$(VIVADO) generated_vivado_project/generated_vivado_project.xpr

clean:
	find ./ -name "generated_hls_project" | xargs rm -rf
	find ./ -name "generated_vivado_project" | xargs rm -rf
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf
	find ./ -name "awsver.txt" | xargs rm -rf
