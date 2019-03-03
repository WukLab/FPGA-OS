#include "chunk_alloc.h"

Chunk_alloc::Chunk_alloc()
{
#pragma HLS DATA_PACK variable=chunk_bitmap
	chunk_bitmap = 0;
}

Chunk_alloc::~Chunk_alloc()
{
}

void Chunk_alloc::handler(axis_sysmmu_alloc& alloc, axis_sysmmu_alloc_ret& alloc_ret,
						axis_sysmmu_ctrl& ctrl, RET_STATUS& ctrl_ret, RET_STATUS* stat)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	if (alloc.empty()) {
		*stat = SUCCESS;
		return;
	}

	sysmmu_alloc_if req = alloc.read();
	switch (req.opcode) {
	case SYSMMU_ALLOC:
		Chunk_alloc::alloc(req, alloc_ret, ctrl, ctrl_ret, stat);
		break;
	case SYSMMU_FREE:
		Chunk_alloc::free(req, alloc_ret, ctrl, ctrl_ret, stat);
		break;
	default:
		*stat = ERROR;
	}
}

void Chunk_alloc::alloc(sysmmu_alloc_if& alloc, axis_sysmmu_alloc_ret& alloc_ret,
						axis_sysmmu_ctrl& ctrl, RET_STATUS& ctrl_ret, RET_STATUS* stat)
{
#pragma HLS PIPELINE
	sysmmu_ctrl_if req;
	sysmmu_alloc_ret_if ret;
	ap_uint<PA_SHIFT> i;
	for (i = 0; i < TABLE_SIZE; i++) {
		if (!chunk_bitmap.get_bit(i)) {
			chunk_bitmap.set_bit(i, 1);
			req.opcode = SYSMMU_ALLOC;
			req.idx = i;
			req.pid = alloc.pid;
			req.rw = alloc.rw;
			ctrl.write(req);
			break;
		}
	}
	if (i < TABLE_SIZE && ctrl_ret == SUCCESS) {
		ret.addr = ADDR(i, BLOCK_SHIFT);
		alloc_ret.write(ret);
		*stat = SUCCESS;
	} else {
		*stat = ERROR;
	}
}

void Chunk_alloc::free(sysmmu_alloc_if& alloc, axis_sysmmu_alloc_ret& alloc_ret,
						axis_sysmmu_ctrl& ctrl, RET_STATUS& ctrl_ret, RET_STATUS* stat)
{
#pragma HLS PIPELINE
	sysmmu_ctrl_if req;
	sysmmu_alloc_ret_if ret;
	ap_uint<TABLE_SHIFT> idx = BLOCK_IDX(alloc.addr);

	if (chunk_bitmap.get_bit(idx)) {
		req.opcode = SYSMMU_FREE;
		req.idx = BLOCK_IDX(alloc.addr);
		req.pid = alloc.pid;
		req.rw = alloc.rw;
		ctrl.write(req);
	} else {
		*stat = ERROR;
	}

	if (ctrl_ret == SUCCESS) {
		chunk_bitmap.set_bit(idx, 0);
		ret.addr = alloc.addr;
		alloc_ret.write(ret);
		*stat = SUCCESS;
	} else {
		*stat = ERROR;
	}
}
