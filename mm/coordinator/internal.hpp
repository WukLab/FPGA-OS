/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#define ENABLE_PR

#include <ap_int.h>
#include <hls_stream.h>

#include <fpga/channel/alloc_seg.h>
#include <fpga/axis_buddy.h>
#include <fpga/axis_mapping.h>
#include <fpga/kernel.h>

#include "mem_cmd.h"
#include "../paging_hashed/hls_mapping/top.hpp"

using namespace hls;

enum FUNCTION_STATUS {
        FUNC_WIP,
        FUNC_DOWN,
        FUNC_FAILED
};

/*
 * @buddy_alloc_req: buddy request for page table
 * @buddy_alloc_ret: buddy return for page table
 * @seg_alloc_req: segment request for buddy allocator
 * @seg_alloc_ret: segment return for buddy allocator
 * @init_buddy_addr: initiate start address for buddy allocator
 * @init_tbl_addr: initiate page table start address
 * @init_hEAP_addr: initiate start address for heap allocator
 */
int init(stream<struct buddy_alloc_if>	*buddy_alloc_req,
		     stream<struct buddy_alloc_ret_if>	*buddy_alloc_ret,
		     stream<struct alloc_seg_in>	*seg_alloc_req,
		     stream<struct alloc_seg_out>	*seg_alloc_ret,
		     stream<unsigned long>		*init_buddy_addr,
		     stream<ap_uint<PA_WIDTH> >		*init_tbl_addr,
		     stream<unsigned long>		*init_heap_addr);

/*
 * @ctrl_in: top-level control signal for memory request (init/alloc/free)
 * @ctrl_out: top-level return signal for memory request (init/alloc/free)
 * @seg_alloc_req: segment request for buddy allocator
 * @seg_alloc_ret: segment return for buddy allocator
 * @buddy_alloc_req: buddy request for physical memory
 * @buddy_alloc_ret: buddy return for physical memory
 * @init_buddy_addr: initiate start address for buddy allocator
 * @init_tbl_addr: initiate page table start address
 * @init_heap_addr: initiate start address for heap allocator
 */
void coord_top(stream<struct mem_cmd_in>		*ctrl_in,
	       stream<struct mem_cmd_out>		*ctrl_out,

	       stream<struct alloc_seg_in>		*seg_alloc_req,
	       stream<struct alloc_seg_out>		*seg_alloc_ret,
	       stream<struct buddy_alloc_if>		*buddy_alloc_req,
	       stream<struct buddy_alloc_ret_if>	*buddy_alloc_ret,

	       stream<unsigned long>			*init_buddy_addr,
	       stream<ap_uint<PA_WIDTH> >		*init_tbl_addr,
	       stream<unsigned long>			*init_heap_addr);
