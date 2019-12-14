/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include "buddy.h"

static Buddy buddy = Buddy();
const int AXI_DEPTH = BUDDY_USER_OFF;

/*
 * TODO:
 * add init_buddy_managed_size
 * and merge port if possible. using two AXI-S is too much.
 */
void buddy_allocator(hls::stream<struct buddy_alloc_if>& alloc,
		     hls::stream<struct buddy_alloc_ret_if>& alloc_ret,
		     hls::stream<unsigned long> *buddy_init,
		     char *dram)
{
#pragma HLS DATA_PACK variable=alloc
#pragma HLS DATA_PACK variable=alloc_ret

#pragma HLS INTERFACE axis register port=alloc
#pragma HLS INTERFACE axis register port=alloc_ret
#pragma HLS INTERFACE axis register port=buddy_init
#pragma HLS INTERFACE m_axi depth=AXI_DEPTH port=dram offset=off
#pragma HLS INTERFACE ap_ctrl_none port=return

	if (!buddy_init->empty())
		buddy.init(buddy_init);

	if (!alloc.empty())
		buddy.handler(alloc, alloc_ret, dram);
}
