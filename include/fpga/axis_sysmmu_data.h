/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file describes sysmmu data interfaces used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_SYSMMU_DATA_
#define _LEGO_FPGA_AXIS_SYSMMU_DATA_

#include "sysmmu_type.h"

template <int PID_WIDTH, int ADDR_WIDTH>
struct sysmmu_indata {
	/*
	 * physical memory datapath input interface, only for permission check
	 *
	 * pid: 	application id
	 * in_addr:	address in
	 * in_size:	axi transfer burst size
	 * in_len:	axi transfer burst length
	 * start:	single that start process
	 */
	ap_uint<PID_WIDTH>	pid;
	ap_uint<ADDR_WIDTH>	in_addr;
	ap_uint<3>		in_size;
	ap_uint<8>		in_len;
	ap_uint<1>		start;
};

template <int ADDR_WIDTH>
struct sysmmu_outdata {
	/*
	 * physical memory datapath output interface, only for permission check
	 *
	 * out_addr: physical address out
	 * done: check finished
	 * drop: 1 if error occurs, 0 if success
	 */
	ap_uint<ADDR_WIDTH>	out_addr;
	ap_uint<1>		done;
	ap_uint<1>		drop;
};

/*
 * read & write interface
 */
typedef struct sysmmu_indata<PID_SHIFT, PA_SHIFT>	sysmmu_indata_if;
typedef struct sysmmu_outdata<PA_SHIFT>			sysmmu_outdata_if;

#endif /* _LEGO_FPGA_AXIS_SYSMMU_DATA_ */
