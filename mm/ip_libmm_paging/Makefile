#
# Copyright (c) 2019, Wuklab, UCSD.
#

VIVADO = vivado

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu118
endif

IP_NAME_PREFIX	:= mm
HLS_IP_CORES	:= coordinator,tmp_va_buddy,buddy_alloc_mux

all:
	$(Q)./generate_hls.sh $(TARGET_BOARD) $(HLS_IP_CORES) $(IP_NAME_PREFIX)
	$(VIVADO) -mode tcl -source run_vivado_$(TARGET_BOARD).tcl

	# mapping table, bram table
	#$(Q)cd ../paging_hashed && ./generate_hls.sh $(TARGET_BOARD)
	# buddy allocator
	#$(Q)make -C ../../alloc
g:
	$(VIVADO) generated_vivado_project/generated_vivado_project.xpr

clean:
	find ./ -name "generated_hls_project" | xargs rm -rf
	find ./ -name "generated_vivado_project" | xargs rm -rf
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf
