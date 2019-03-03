#include "sysmmu.h"

Sysmmu::Sysmmu()
{
#pragma HLS DATA_PACK variable=sysmmu_table struct_level
#pragma HLS ARRAY_PARTITION variable=sysmmu_table complete dim=1
}

Sysmmu::~Sysmmu()
{
}

void Sysmmu::sysmmu_data_hanlder(axis_sysmmu_data& datapath, RET_STATUS* stat)
{
#pragma HLS PIPELINE
#pragma HLS INLINE
	if (datapath.empty()) {
		*stat = SUCCESS;
		return;
	}

	sysmmu_data_if data = datapath.read();
	*stat = check(data);
}

void Sysmmu::sysmmu_ctrl_hanlder(axis_sysmmu_ctrl& ctrlpath, RET_STATUS* stat)
{
#pragma HLS PIPELINE
#pragma HLS INLINE
	/*
	 * FIFO empty checked by caller for parallel execution
	 * (I don't know why)
	 */
	sysmmu_ctrl_if ctrl = ctrlpath.read();
	switch (ctrl.opcode) {
	case SYSMMU_ALLOC:
		*stat = insert(ctrl);
		break;
	case SYSMMU_FREE:
		*stat = del(ctrl);
		break;
	default:
		*stat = ERROR;
	}
}

RET_STATUS Sysmmu::insert(sysmmu_ctrl_if& ctrl)
{
#pragma HLS PIPELINE
	ap_uint<TABLE_SHIFT> idx = ctrl.idx;
	if (sysmmu_table[idx].valid)
		return ERROR;

	sysmmu_table[idx].pid = ctrl.pid;
	if (ctrl.rw == MEMWIRTE)
		sysmmu_table[idx].rw = MEMWIRTE;
	else
		sysmmu_table[idx].rw = MEMREAD;
	sysmmu_table[idx].valid = 1;
	return SUCCESS;
}

RET_STATUS Sysmmu::del(sysmmu_ctrl_if& ctrl)
{
#pragma HLS PIPELINE
	ap_uint<TABLE_SHIFT> idx = ctrl.idx;
	if (!sysmmu_table[idx].valid)
		return ERROR;

	sysmmu_table[idx].valid = 0;
	return SUCCESS;
}

RET_STATUS Sysmmu::check(sysmmu_data_if& data)
{
#pragma HLS PIPELINE
	/* start index and end index are inclusive */
	RET_STATUS ret = SUCCESS;
	ap_uint<TABLE_SHIFT + 1> start_idx = BLOCK_IDX(data.addr);
	ap_uint<TABLE_SHIFT + 1> end_idx = BLOCK_IDX(data.addr + data.size - 1);
	TABLE_LOOP:
	for (ap_uint<TABLE_SHIFT + 1> i = 0; i < TABLE_SIZE; i++) {
#pragma HLS UNROLL
		if (i < start_idx || i > end_idx)
			continue;

		if (!sysmmu_table[i].valid || sysmmu_table[i].pid != data.pid ||
			(data.rw == MEMWIRTE && sysmmu_table[i].rw != MEMWIRTE))
			ret = ERROR;
	}
	return ret;
}
