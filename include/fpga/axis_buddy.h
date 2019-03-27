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
#include "buddy_type.h"

template <int ORDER_WIDTH, int ADDR_WIDTH>
struct buddy_alloc {
	/*
	 * library buddy allocator, to save the bandwidth,
	 * alloc and free use the same structure, so some field maybe useless
	 * for certain opcode, see below for detail:
	 *
	 * opcode: ALLOC or FREE
	 * addr:   address used for free,
	 *         if opcode is ALLOC, this field is useless
	 * order:  size of request with order of 2, this field is available for
	 * 	   both ALLOC and FREE, partial free is not allowed
	 */
	OPCODE			opcode;
	ap_uint<ADDR_WIDTH>	addr;
	ap_uint<ORDER_WIDTH>	order;
};

template <int ADDR_WIDTH>
struct buddy_alloc_ret {
	/*
	 * buddy allocator return address, the return is only
	 * meaningful for ALLOC request.
	 *
	 * stat: status of return
	 * addr: address assigned, useless when request is FREE
	 */
	ap_uint<1>		stat;
	ap_uint<ADDR_WIDTH>	addr;
};

typedef struct buddy_alloc<ORDER_MAX, PA_SHIFT>	buddy_alloc_if;
typedef struct buddy_alloc_ret<PA_SHIFT>	buddy_alloc_ret_if;

typedef hls::stream<buddy_alloc_if>		axis_buddy_alloc;
typedef hls::stream<buddy_alloc_ret_if>		axis_buddy_alloc_ret;

void buddy_allocator(axis_buddy_alloc& alloc, axis_buddy_alloc_ret& alloc_ret, char* dram);

#endif /* _LEGO_FPGA_AXIS_SYSMMU_ALLOC_ */
