/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/*
 * This file describes Buddy Allocator data structures
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_BUDDY_H_
#define _LEGO_FPGA_AXIS_BUDDY_H_

#include <ap_int.h>
#include <hls_stream.h>
#include "mem_common.h"

enum {
	BUDDY_ALLOC = 0,
	BUDDY_FREE = 1,
};

enum {
	BUDDY_SUCCESS = 0,
	BUDDY_FAILED = 1
};

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
	ap_uint<PA_WIDTH>	addr;
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
	ap_uint<PA_WIDTH>	addr;
};

void buddy_allocator(hls::stream<struct buddy_alloc_if>& alloc,
		     hls::stream<struct buddy_alloc_ret_if>& alloc_ret,
		     hls::stream<unsigned long>* buddy_init, char *dram);

void virt_addr_allocator(hls::stream<struct buddy_alloc_if> &alloc,
		    hls::stream<struct buddy_alloc_ret_if> &alloc_ret,
		    hls::stream<unsigned long> &buddy_init, char *dram);
#endif /* _LEGO_FPGA_AXIS_BUDDY_H_ */
