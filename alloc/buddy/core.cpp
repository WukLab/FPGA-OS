/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "buddy.h"

static Buddy buddy = Buddy();
const int AXI_DEPTH = SIM_DRAM_SIZE;

void core(axis_buddy_alloc& alloc, axis_buddy_alloc_ret* alloc_ret, char* dram, RET_STATUS* stat)
{
#pragma HLS INTERFACE axis register forward port=alloc
#pragma HLS INTERFACE axis register reverse port=alloc_ret
#pragma HLS INTERFACE ap_vld port=stat
#pragma HLS INTERFACE m_axi depth=AXI_DEPTH port=dram offset=off

	buddy.handler(alloc, alloc_ret, dram, stat);
}
