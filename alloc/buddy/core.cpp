/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "buddy.h"

static Buddy buddy = Buddy();
const int AXI_DEPTH = SIM_DRAM_SIZE;

void buddy_allocator(hls::stream<struct buddy_alloc_if>& alloc,
		     hls::stream<struct buddy_alloc_ret_if>& alloc_ret,
		     char *dram)
{
#pragma HLS DATA_PACK variable=alloc
#pragma HLS DATA_PACK variable=alloc_ret

#pragma HLS INTERFACE axis register port=alloc
#pragma HLS INTERFACE axis register port=alloc_ret
#pragma HLS INTERFACE m_axi depth=AXI_DEPTH port=dram offset=off

	buddy.handler(alloc, alloc_ret, dram);
}
