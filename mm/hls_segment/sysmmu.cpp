/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */

#include "sysmmu.h"

static struct sysmmu_entry sysmmu_table[TABLE_SIZE];

void sysmmu_data_hanlder(sysmmu_indata& rd_in, sysmmu_outdata* rd_out,
			 sysmmu_indata& wr_in, sysmmu_outdata* wr_out)
{
#pragma HLS ARRAY_PARTITION variable=sysmmu_table complete dim=1
#pragma HLS PIPELINE
#pragma HLS INLINE
	sysmmu_data_read(rd_in, rd_out);
	sysmmu_data_write(wr_in, wr_out);
}


void sysmmu_ctrl_hanlder(hls::stream<struct sysmmu_ctrl_if>& ctrlpath, ap_uint<1>* stat)
{
#pragma HLS PIPELINE
#pragma HLS INLINE
	/*
	 * FIFO empty checked by caller for parallel execution
	 * (I don't know why)
	 */
	struct sysmmu_ctrl_if ctrl = ctrlpath.read();

	switch (ctrl.opcode) {
	case 0: // ALLOC
		*stat = insert(ctrl);
		break;
	case 1: // FREE
		*stat = del(ctrl);
		break;
	default:
		*stat = 1;
	}
}

void sysmmu_data_write(sysmmu_indata& wr_in, sysmmu_outdata* wr_out)
{
#pragma HLS PIPELINE
	wr_out->out_addr = wr_in.in_addr;
	wr_out->drop = check_write(wr_in);
}

void sysmmu_data_read(sysmmu_indata& rd_in, sysmmu_outdata* rd_out)
{
#pragma HLS PIPELINE
	rd_out->out_addr = rd_in.in_addr;
	rd_out->drop = check_read(rd_in);
}


ap_uint<1> insert(sysmmu_ctrl_if& ctrl)
{
#pragma HLS PIPELINE
	ap_uint<TABLE_TYPE> idx = ctrl.idx;
	if (sysmmu_table[idx].valid)
		return 1;

	sysmmu_table[idx].pid = ctrl.pid;
	if (ctrl.rw == 1)
		sysmmu_table[idx].rw = 1;
	else
		sysmmu_table[idx].rw = 0;
	sysmmu_table[idx].valid = 1;
	return 0;
}

ap_uint<1> del(sysmmu_ctrl_if& ctrl)
{
#pragma HLS PIPELINE
	ap_uint<TABLE_TYPE> idx = ctrl.idx;
	if (!sysmmu_table[idx].valid)
		return 1;

	sysmmu_table[idx].valid = 0;
	return 0;
}

ap_uint<1> check_read(sysmmu_indata& rd_in)
{
#pragma HLS PIPELINE
	/* start index and end index are inclusive */
	ap_uint<1> ret = 0;
	ap_uint<16> size = ap_uint<16>(rd_in.in_len) << ap_uint<16>(rd_in.in_size);
	ap_uint<TABLE_TYPE> start_idx = BLOCK_IDX(rd_in.in_addr);
	ap_uint<TABLE_TYPE> end_idx = BLOCK_IDX(rd_in.in_addr + size - 1);
	TABLE_LOOP:
	for (ap_uint<TABLE_TYPE> i = 0; i < TABLE_SIZE; i++) {
#pragma HLS UNROLL
		if (i < start_idx || i > end_idx)
			continue;

		if (!sysmmu_table[i].valid || sysmmu_table[i].pid != rd_in.pid) {
			ret = 1;
		}
	}
	return ret;
}

ap_uint<1> check_write(sysmmu_indata& wr_in)
{
#pragma HLS PIPELINE
	/* start index and end index are inclusive */
	ap_uint<1> ret = 0;
	ap_uint<16> size = ap_uint<16>(wr_in.in_len) << ap_uint<16>(wr_in.in_size);
	ap_uint<TABLE_TYPE> start_idx = BLOCK_IDX(wr_in.in_addr);
	ap_uint<TABLE_TYPE> end_idx = BLOCK_IDX(wr_in.in_addr + size - 1);
	TABLE_LOOP:
	for (ap_uint<TABLE_TYPE> i = 0; i < TABLE_SIZE; i++) {
#pragma HLS UNROLL
		if (i < start_idx || i > end_idx)
			continue;

		if (!sysmmu_table[i].valid || sysmmu_table[i].pid != wr_in.pid ||
			sysmmu_table[i].rw != 1) {
			ret = 1;
		}
	}
	return ret;
}
