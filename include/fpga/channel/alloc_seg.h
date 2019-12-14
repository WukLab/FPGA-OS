/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/*
 * This file describes the channel interface exposed by both
 * 1) fixed-size segment allocator and 2) variable-size segment allocator.
 */

#ifndef _INCLUDE_FPGA_CHANNEL_ALLOC_SEG_H_
#define _INCLUDE_FPGA_CHANNEL_ALLOC_SEG_H_

#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/config/memory.h>

enum alloc_seg_opcode {
	SEG_RESERVED,
	SEG_ALLOC,
	SEG_FREE,
};

enum alloc_seg_retcode {
	SEG_SUCCESS,
	SEG_FAILED
};

struct alloc_seg_in {
	ap_uint<8>					opcode;
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	addr_len;
};

struct alloc_seg_out {
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	addr_len;
	ap_uint<8>					ret;
};

#endif /* _INCLUDE_FPGA_CHANNEL_ALLOC_SEG_H_ */
