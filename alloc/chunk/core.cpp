#include "chunk_alloc.h"

static Chunk_alloc chunk_allocator = Chunk_alloc();

void chunk_alloc(axis_sysmmu_alloc& alloc, axis_sysmmu_alloc_ret& alloc_ret,
		axis_sysmmu_ctrl& ctrl, RET_STATUS& ctrl_ret, RET_STATUS* stat)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE axis register both port=alloc
#pragma HLS INTERFACE axis register both port=alloc_ret
#pragma HLS INTERFACE axis register both port=ctrl
#pragma HLS INTERFACE ap_vld port=ctrl_ret
	chunk_allocator.handler(alloc, alloc_ret, ctrl, ctrl_ret, stat);
}
