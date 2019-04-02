/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file descirbes system mmu control interfaces used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_SYSMMU_ALLOC_
#define _LEGO_FPGA_AXIS_SYSMMU_ALLOC_

#include <fpga/axis_sysmmu_ctrl.h>

struct sysmmu_alloc_if {
	/*
	 * physical memory unit memory ctrl structure, this interface sits
	 * between application and sysmmu allocator, to save the bandwidth,
	 * alloc and free use the same structure, so some field maybe useless
	 * for certain opcode, see below for detail:
	 *
	 * opcode: ALLOC = 0 or FREE = 1
	 * pid: application id
	 * rw:	application rw permission for this malloc, 
	 * 	if opcode is FREE, this field is useless
	 * addr: address used for free, 
	 *       if opcode is ALLOC, this field is useless
	 */
	ap_uint<1>		opcode;
	ap_uint<PID_SHIFT>	pid;
	ap_uint<1>		rw;
	ap_uint<PA_SHIFT>	addr;
};

struct sysmmu_alloc_ret_if {
	/*
	 * physical memory unit memory ctrl return structure, this interface 
	 * sits between application and sysmmu allocator, the return is only
	 * meaningful for ALLOC request
	 *
	 * addr: address assigned, useless when request is FREE
	 */
	ap_uint<PA_SHIFT>	addr;
};

void chunk_alloc(hls::stream<sysmmu_alloc_if>& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		 hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat);

#endif /* _LEGO_FPGA_AXIS_SYSMMU_ALLOC_ */
