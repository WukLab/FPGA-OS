#
# Copyright (c) 2019, Wuklab, UCSD.
#

ifeq ($(TARGET_BOARD), )
  TARGET_BOARD = vcu118
endif

IP_NAME_PREFIX	:= mm
HLS_IP_CORES	:= segfix,segvar

#
# sys must be the last one in the list
#
all:
	$(Q)./generate_hls.sh $(TARGET_BOARD) $(HLS_IP_CORES) $(IP_NAME_PREFIX)
	$(Q)make -C axi_rab
	$(Q)make -C paging_hashed 

	# Integrated IPs
	$(Q)make -C ip_libmm_paging
	$(Q)make -C ip_libmm_segfix
	$(Q)make -C ip_sysmm_segfix

clean:
	$(Q)make -C axi_wrapper clean
	$(Q)make -C mapping clean
	$(Q)make -C ip_libmmu_paging clean
	$(Q)make -C ip_libmmu_segment clean
	$(Q)make -C ip_sysmmu_segment clean
