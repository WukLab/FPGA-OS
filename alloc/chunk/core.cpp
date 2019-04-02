#include "chunk_alloc.h"

static Chunk_alloc chunk_allocator = Chunk_alloc();

void chunk_alloc(hls::stream<sysmmu_alloc_if>& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		 hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE axis register both port=alloc
#pragma HLS INTERFACE axis register both port=alloc_ret
#pragma HLS INTERFACE axis register both port=ctrl
#pragma HLS INTERFACE ap_vld port=ctrl_ret
	chunk_allocator.handler(alloc, alloc_ret, ctrl, ctrl_ret, stat);
}
