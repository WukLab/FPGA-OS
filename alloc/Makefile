ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu118
endif

all:
	$(Q)./generate_hls.sh $(TARGET_BOARD)

clean:
	find ./ -name "*.log" | xargs rm -rf
	find ./ -name "*.jou" | xargs rm -rf
	find ./ -name "*.str" | xargs rm -rf
	find ./ -name ".Xil" | xargs rm -rf
