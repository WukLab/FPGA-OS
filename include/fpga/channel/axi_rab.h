/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/*
 * Public interface for the AXI Remapping Address Block.
 * This IP block is used by both LibMM and SysMM.
 */

#ifndef _INCLUDE_FPGA_CHANNEL_AXI_RAB_H_
#define _INCLUDE_FPGA_CHANNEL_AXI_RAB_H_

#include <fpga/config/kernel.h>

struct rab_request {
	/*
	 * in_addr:	address in
	 * in_len:	axi transfer burst length
	 * in_size:	axi transfer burst size
	 * pid: 	application id
	 */
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	in_addr;
	ap_uint<CONFIG_PID_WIDTH>			pid;
	ap_uint<8>					in_len;
	ap_uint<3>					in_size;
};

struct rab_reply {
	/*
	 * physical memory datapath output interface, only for permission check
	 *
	 * out_addr: physical address out
	 * drop: 1 if error occurs, 0 if success
	 */
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	out_addr;
	ap_uint<1>					drop;
};

#endif /* _INCLUDE_FPGA_CHANNEL_AXI_RAB_H_ */
