/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include "buddy.h"

static Buddy buddy = Buddy();
const int AXI_DEPTH = SIM_DRAM_SIZE;

unsigned long buddy_managed_base;
unsigned long buddy_managed_size;
bool buddy_initialized = false;

static inline void init_buddy(hls::stream<unsigned long> *buddy_init)
{
#pragma HLS INLINE
	buddy_managed_base = buddy_init->read();
	buddy_initialized = true;
}

/*
 * TODO:
 * add init_buddy_managed_size
 * and merge port if possible. using two AXI-S is too much.
 */
void buddy_allocator(hls::stream<struct buddy_alloc_if>& alloc,
		     hls::stream<struct buddy_alloc_ret_if>& alloc_ret,
		     hls::stream<unsigned long> *init_buddy_managed_base,
		     char *dram)
{
#pragma HLS DATA_PACK variable=alloc
#pragma HLS DATA_PACK variable=alloc_ret

#pragma HLS INTERFACE axis register port=alloc
#pragma HLS INTERFACE axis register port=alloc_ret
#pragma HLS INTERFACE axis register port=init_buddy_managed_base
#pragma HLS INTERFACE m_axi depth=AXI_DEPTH port=dram offset=off
#pragma HLS INTERFACE ap_ctrl_none port=return

	if (!init_buddy_managed_base->empty())
		init_buddy(init_buddy_managed_base);

	if (!alloc.empty())
		buddy.handler(alloc, alloc_ret, dram);
}
