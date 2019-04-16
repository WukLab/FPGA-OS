ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

all:
	$(Q)./generate_hls.sh $(TARGET_BOARD)
	$(Q)make -C ip_sysnet

hls:
	$(Q)./generate_hls.sh $(TARGET_BOARD)

clean:
	$(Q)make -C hls_rx clean
	$(Q)make -C hls_tx clean
	$(Q)make -C ip_sysnet clean
