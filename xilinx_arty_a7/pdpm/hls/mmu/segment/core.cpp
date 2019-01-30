#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "core.hpp"

using namespace hls;

/*
 * This function will translate the virtual address sent from MMU upper layer
 * and send back the physical address.
 *
 * TODO: still need to figure out how to indicate error etc.
 * Especially if there is fault, the pipeline may have to stall.
 * This maybe relevant to how MC deal with long DRAM read. Check it maybe.
 */
void translate_segment(trans_meta_axis_t *in_va, trans_meta_axis_t *out_pa)
{
	#pragma HLS DATA_PACK variable=in_va
	#pragma HLS DATA_PACK variable=out_pa
	#pragma HLS INTERFACE axis register both port=in_va name=in_va
	#pragma HLS INTERFACE axis register both port=out_pa name=out_pa

	/* Block-level */
	#pragma HLS PIPELINE II=1 enable_flush

	trans_meta_t tmp;

	if (in_va->empty())
		return;

	tmp = in_va->read();

	out_pa->write(tmp);
}
