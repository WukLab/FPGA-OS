#
# Copyright (c) 2019, Wuklab, Purdue University.
#

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu108
endif

#
# sys must be the last one in the list
#
all:
	# Generate HLS IPs
	# - HLS segment
	# - HLS paging
	$(Q)./generate_hls.sh $(TARGET_BOARD)
	$(Q)make -C axi_wrapper

	# Integrated IPs
	$(Q)make -C ip_libmmu_paging
	$(Q)make -C ip_libmmu_segment
	$(Q)make -C ip_sysmmu_segment
