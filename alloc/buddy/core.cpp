/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "buddy.h"

static Buddy buddy = Buddy();
const int AXI_DEPTH = SIM_DRAM_SIZE;

void buddy_allocator(axis_buddy_alloc& alloc, axis_buddy_alloc_ret& alloc_ret, char* dram)
{
//#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS DATA_PACK variable=alloc
#pragma HLS DATA_PACK variable=alloc_ret

#pragma HLS INTERFACE axis register port=alloc
#pragma HLS INTERFACE axis register port=alloc_ret
#pragma HLS INTERFACE m_axi depth=AXI_DEPTH port=dram offset=off

	buddy.handler(alloc, alloc_ret, dram);
}
