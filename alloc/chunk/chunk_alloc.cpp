#include "chunk_alloc.h"

Chunk_alloc::Chunk_alloc()
{
#pragma HLS DATA_PACK variable=chunk_bitmap
	chunk_bitmap = 0;
}

void
Chunk_alloc::handler(hls::stream<sysmmu_alloc_if>& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		     hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	if (alloc.empty()) {
		*stat = 0;
		return;
	}

	struct sysmmu_alloc_if req = alloc.read();
	switch (req.opcode) {
	case 0: // Alloc
		Chunk_alloc::alloc(req, alloc_ret, ctrl, ctrl_ret, stat);
		break;
	case 1: // Free
		Chunk_alloc::free(req, alloc_ret, ctrl, ctrl_ret, stat);
		break;
	default:
		*stat = 1;
	}
}

void
Chunk_alloc::alloc(struct sysmmu_alloc_if& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		   hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat)
{
#pragma HLS PIPELINE
	struct sysmmu_ctrl_if req;
	struct sysmmu_alloc_ret_if ret;
	ap_uint<PA_SHIFT> i;
	for (i = 0; i < TABLE_SIZE; i++) {
		if (!chunk_bitmap.get_bit(i)) {
			chunk_bitmap.set_bit(i, 1);
			req.opcode = 0;	// Alloc opcode
			req.idx = i;
			req.pid = alloc.pid;
			req.rw = alloc.rw;
			ctrl.write(req);
			break;
		}
	}
	if (i < TABLE_SIZE && ctrl_ret == 0) {
		ret.addr = ADDR(i, BLOCK_SHIFT);
		alloc_ret.write(ret);
		*stat = 0;
	} else {
		*stat = 1;
	}
}

void
Chunk_alloc::free(struct sysmmu_alloc_if& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		  hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat)
{
#pragma HLS PIPELINE
	struct sysmmu_ctrl_if req;
	struct sysmmu_alloc_ret_if ret;
	ap_uint<TABLE_TYPE> idx = BLOCK_IDX(alloc.addr);

	if (chunk_bitmap.get_bit(idx)) {
		req.opcode = 1; // Free opcode
		req.idx = BLOCK_IDX(alloc.addr);
		req.pid = alloc.pid;
		req.rw = alloc.rw;
		ctrl.write(req);
	} else {
		*stat = 1;
	}

	if (ctrl_ret == 0) {
		chunk_bitmap.set_bit(idx, 0);
		ret.addr = alloc.addr;
		alloc_ret.write(ret);
		*stat = 0;
	} else {
		*stat = 1;
	}
}
