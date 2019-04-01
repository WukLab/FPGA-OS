#include "sysmmu.h"

Sysmmu::Sysmmu()
{
#pragma HLS DATA_PACK variable=sysmmu_table struct_level
#pragma HLS ARRAY_PARTITION variable=sysmmu_table complete dim=1
}

Sysmmu::~Sysmmu()
{
}

void Sysmmu::sysmmu_data_hanlder(sysmmu_indata_if& rd_in, sysmmu_outdata_if* rd_out,
				 sysmmu_indata_if& wr_in, sysmmu_outdata_if* wr_out)
{
#pragma HLS PIPELINE
#pragma HLS INLINE
	sysmmu_data_read(rd_in, rd_out);
	sysmmu_data_write(wr_in, wr_out);
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

void Sysmmu::sysmmu_data_write(sysmmu_indata_if& wr_in, sysmmu_outdata_if* wr_out)
{
#pragma HLS PIPELINE
	switch (wr_in.start) {
	case 1:
		/* init */
		wr_out->done = 0;
		wr_out->drop = 0;
		wr_out->out_addr = wr_in.in_addr;

		/* check starts */
		wr_out->drop = ap_uint<1>(check_write(wr_in));
		wr_out->done = 1;
		break;
	default:
		wr_out->done = 0;
		wr_out->drop = 0;
		wr_out->out_addr = 0;
	}
}

void Sysmmu::sysmmu_data_read(sysmmu_indata_if& rd_in, sysmmu_outdata_if* rd_out)
{
#pragma HLS PIPELINE
	switch (rd_in.start) {
	case 1:
		/* init */
		rd_out->done = 0;
		rd_out->drop = 0;
		rd_out->out_addr = rd_in.in_addr;

		/* check starts */
		rd_out->drop = ap_uint<1>(check_read(rd_in));
		rd_out->done = 1;
		break;
	default:
		rd_out->done = 0;
		rd_out->drop = 0;
		rd_out->out_addr = 0;
	}
}


RET_STATUS Sysmmu::insert(sysmmu_ctrl_if& ctrl)
{
#pragma HLS PIPELINE
	ap_uint<TABLE_TYPE> idx = ctrl.idx;
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
	ap_uint<TABLE_TYPE> idx = ctrl.idx;
	if (!sysmmu_table[idx].valid)
		return ERROR;

	sysmmu_table[idx].valid = 0;
	return SUCCESS;
}

RET_STATUS Sysmmu::check_read(sysmmu_indata_if& rd_in)
{
#pragma HLS PIPELINE
	/* start index and end index are inclusive */
	RET_STATUS ret = SUCCESS;
	ap_uint<16> size = ap_uint<16>(rd_in.in_len) << ap_uint<16>(rd_in.in_size);
	ap_uint<TABLE_TYPE> start_idx = BLOCK_IDX(rd_in.in_addr);
	ap_uint<TABLE_TYPE> end_idx = BLOCK_IDX(rd_in.in_addr + size - 1);
	TABLE_LOOP:
	for (ap_uint<TABLE_TYPE> i = 0; i < TABLE_SIZE; i++) {
#pragma HLS UNROLL
		if (i < start_idx || i > end_idx)
			continue;

		if (!sysmmu_table[i].valid || sysmmu_table[i].pid != rd_in.pid)
			ret = ERROR;
	}
	return ret;
}

RET_STATUS Sysmmu::check_write(sysmmu_indata_if& wr_in)
{
#pragma HLS PIPELINE
	/* start index and end index are inclusive */
	RET_STATUS ret = SUCCESS;
	ap_uint<16> size = ap_uint<16>(wr_in.in_len) << ap_uint<16>(wr_in.in_size);
	ap_uint<TABLE_TYPE> start_idx = BLOCK_IDX(wr_in.in_addr);
	ap_uint<TABLE_TYPE> end_idx = BLOCK_IDX(wr_in.in_addr + size - 1);
	TABLE_LOOP:
	for (ap_uint<TABLE_TYPE> i = 0; i < TABLE_SIZE; i++) {
#pragma HLS UNROLL
		if (i < start_idx || i > end_idx)
			continue;

		if (!sysmmu_table[i].valid || sysmmu_table[i].pid != wr_in.pid ||
			sysmmu_table[i].rw != MEMWIRTE)
			ret = ERROR;
	}
	return ret;
}
