#
# Copyright (c) 2019, Wuklab, UCSD
#

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu118
endif

IP_NAME_PREFIX := alloc

#HLS_IP_CORES := buddy,chunk,segfix,segvar
HLS_IP_CORES := segfix,segvar

all:
	$(Q)./generate_hls.sh $(TARGET_BOARD) $(HLS_IP_CORES) $(IP_NAME_PREFIX)

clean:
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf
