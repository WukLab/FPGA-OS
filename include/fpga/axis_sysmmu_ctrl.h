/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file describes sysmmu control interfaces used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_SYSMMU_CTRL_
#define _LEGO_FPGA_AXIS_SYSMMU_CTRL_

#include <ap_int.h>
#include <hls_stream.h>
#include "mem_common.h"

struct sysmmu_ctrl_if {
	/*
	 * physical memory unit memory ctrl structure, this interface sits
	 * between sysmmu allocator and sysmmu unit:
	 *
	 * opcode: ALLOC=0 or FREE=1
	 * rw:	READ=0, WRITE=1
	 * pid: application id
	 * addr: address to be allocated or to be freed, 
	 */
	ap_uint<1>		opcode;
	ap_uint<1>		rw;
	ap_uint<PID_SHIFT>	pid;
	ap_uint<TABLE_TYPE>	idx;
};

void mm_segment_top(hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>* ctrl_stat,
		    struct sysmmu_indata& rd_in, struct sysmmu_outdata* rd_out,
		    struct sysmmu_indata& wr_in, struct sysmmu_outdata* wr_out);

#endif /* _LEGO_FPGA_AXIS_SYSMMU_CTRL_ */
