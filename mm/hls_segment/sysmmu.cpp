/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */

#include "sysmmu.h"

/* this define ignore permission check */
#define IGNORE_PERM_CHECK

static struct sysmmu_entry sysmmu_table[TABLE_SIZE];

void
sysmmu_data_hanlder(hls::stream<sysmmu_indata>& rd_in, hls::stream<sysmmu_outdata>& rd_out,
		    hls::stream<sysmmu_indata>& wr_in, hls::stream<sysmmu_outdata>& wr_out)
{
	check_read(rd_in, rd_out);
	check_write(wr_in, wr_out);
}

void sysmmu_ctrl_hanlder(hls::stream<sysmmu_ctrl_if>& ctrlpath, hls::stream<ap_uint<1> >& ctrl_stat)
{
#pragma HLS ARRAY_PARTITION variable=sysmmu_table complete dim=1

	sysmmu_ctrl_if ctrl = ctrlpath.read();
	ap_uint<1> stat;
	switch (ctrl.opcode) {
	case CHUNK_ALLOC:
		stat = insert(ctrl);
		break;
	case CHUNK_FREE:
		stat = del(ctrl);
		break;
	}
	ctrl_stat.write(stat);
}

ap_uint<1> insert(sysmmu_ctrl_if& ctrl)
{
	ap_uint<TABLE_TYPE> idx = ctrl.idx;
	if (sysmmu_table[idx].valid) {
		return 1;
	}

	sysmmu_table[idx].pid = ctrl.pid;
	sysmmu_table[idx].rw = ctrl.rw;
	sysmmu_table[idx].valid = 1;
	return 0;
}

ap_uint<1> del(sysmmu_ctrl_if& ctrl)
{
	ap_uint<TABLE_TYPE> idx = ctrl.idx;
	if (!sysmmu_table[idx].valid) {
		return 1;
	}

	sysmmu_table[idx].valid = 0;
	return 0;
}

void check_read(hls::stream<sysmmu_indata>& rd_in, hls::stream<sysmmu_outdata>& rd_out)
{

	if (rd_in.empty())
		return;

	sysmmu_indata in = rd_in.read();
	sysmmu_outdata out = {in.in_addr, 0};

	/* start index and end index are inclusive */
	ap_uint<16> size = ap_uint<16>(in.in_len) << ap_uint<16>(in.in_size);
	ap_uint<TABLE_TYPE> start_idx = CHUNK_IDX(in.in_addr);
	ap_uint<TABLE_TYPE> end_idx = CHUNK_IDX(in.in_addr + size - 1);
	TABLE_LOOP:
	for (ap_uint<TABLE_TYPE> i = 0; i < TABLE_SIZE; i++) {
#pragma HLS UNROLL
		if (i < start_idx || i > end_idx)
			continue;


		if (!sysmmu_table[i].valid || sysmmu_table[i].pid != in.pid) {
#ifndef IGNORE_PERM_CHECK
			out.drop = 1;
#endif
			break;
		}

	}
	rd_out.write(out);
}

void check_write(hls::stream<sysmmu_indata>& wr_in, hls::stream<sysmmu_outdata>& wr_out)
{

	if (wr_in.empty())
		return;

	sysmmu_indata in = wr_in.read();
	sysmmu_outdata out = {in.in_addr, 0};

	/* start index and end index are inclusive */
	ap_uint<16> size = ap_uint<16>(in.in_len) << ap_uint<16>(in.in_size);
	ap_uint<TABLE_TYPE> start_idx = CHUNK_IDX(in.in_addr);
	ap_uint<TABLE_TYPE> end_idx = CHUNK_IDX(in.in_addr + size - 1);
	TABLE_LOOP:
	for (ap_uint<TABLE_TYPE> i = 0; i < TABLE_SIZE; i++) {
#pragma HLS UNROLL
		if (i < start_idx || i > end_idx)
			continue;

		if (!sysmmu_table[i].valid || sysmmu_table[i].pid != in.pid ||
			sysmmu_table[i].rw != 1) {
#ifndef IGNORE_PERM_CHECK
			out.drop = 1;
#endif
			break;
		}
	}
	wr_out.write(out);
}
