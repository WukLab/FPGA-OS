ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = arty_a7
endif

# sys must be the last one in the list.
all:
	$(Q)./generate_hls.sh $(TARGET_BOARD)
	#$(Q)make -C sys
