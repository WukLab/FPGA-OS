#
# Copyright (c) 2019, Wuklab, UCSD.
#

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu118
  export TARGET_BOARD
endif

#
# sys must be the last one in the list
#
all:
	# Standalone IPs
	$(Q)./generate_hls.sh $(TARGET_BOARD)
	$(Q)make -C axi_rab
	$(Q)make -C mapping

	# Integrated IPs
	$(Q)make -C ip_libmmu_paging
	$(Q)make -C ip_libmmu_segment
	$(Q)make -C ip_sysmmu_segment

clean:
	$(Q)make -C axi_wrapper clean
	$(Q)make -C mapping clean
	$(Q)make -C ip_libmmu_paging clean
	$(Q)make -C ip_libmmu_segment clean
	$(Q)make -C ip_sysmmu_segment clean
