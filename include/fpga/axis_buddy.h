/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file describes Buddy Allocator data structures
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_SYSMMU_ALLOC_
#define _LEGO_FPGA_AXIS_SYSMMU_ALLOC_

#include <ap_int.h>
#include <hls_stream.h>
#include "mem_common.h"

struct buddy_alloc_if {
	/*
	 * library buddy allocator, to save the bandwidth,
	 * alloc and free use the same structure, so some field maybe useless
	 * for certain opcode, see below for detail:
	 *
	 * opcode: ALLOC = 0 or FREE = 1
	 * addr:   address used for free,
	 *         if opcode is ALLOC, this field is useless
	 * order:  size of request with order of 2, this field is available for
	 * 	   both ALLOC and FREE, partial free is not allowed
	 */
	ap_uint<1>		opcode;
	ap_uint<PA_SHIFT>	addr;
	ap_uint<ORDER_MAX>	order;
};

struct buddy_alloc_ret_if {
	/*
	 * buddy allocator return address, the return is only
	 * meaningful for ALLOC request.
	 *
	 * stat: status of return
	 * addr: address assigned, useless when request is FREE
	 */
	ap_uint<1>		stat;
	ap_uint<PA_SHIFT>	addr;
};

void buddy_allocator(hls::stream<buddy_alloc_if>& alloc, hls::stream<buddy_alloc_ret_if>& alloc_ret, char* dram);

#endif /* _LEGO_FPGA_AXIS_SYSMMU_ALLOC_ */
