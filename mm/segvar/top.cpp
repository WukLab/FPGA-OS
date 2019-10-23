/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/*
 * This file describes the segment table in the SysMM IP.
 * Note that this is NOT the complete SysMM IP.
 * We still need the AXI RAB sitting on the AXI-MM path.
 *
 * This IP share most of the infrastructure code with the fixed-size segment.
 * The difference lies in the parser() function.
 */

#include <fpga/config/process.h>
#include <fpga/config/memory.h>
#include <fpga/channel/alloc_seg.h>
#include <fpga/channel/axi_rab.h>
#include "internal.h"

using namespace hls;

struct segvar_entry table[NR_MAX_SEGVAR_ENTRIES];

/*
 * This is the base physical address of the managed DRAM.
 * And the managed physical DRAM size in bytes.
 *
 * TODO
 * There should be someway to change this on the runtime.
 */
ap_uint<64> managed_base_address = 0;
ap_uint<64> managed_size_in_bytes;

/*
 * This function aggregates all the inputs, and then cook them
 * into the internal pipeline word that will be passed down.
 *
 * XXX
 * How can we aggregate the rd/wr requests into one pipeline word?
 * I guess control/data must be different pi words.
 */
static void aggregate_input(stream<struct alloc_seg_in> *ctl_in,
			    stream<struct rab_request> *rd_in,
			    stream<struct rab_request> *wr_in,
			    stream<struct pipeline_info> *pi)
{
#pragma HLS INLINE OFF
#pragma HLS PIPELINE

	struct pipeline_info out = { 0 };

	if (!ctl_in->empty()) {
		struct alloc_seg_in cin;
		cin = ctl_in->read();

		out.type = SYSMM_REQUEST_CONTROL;
		out.pid = 0;
		out.cp_in_opcode = cin.opcode;
		out.cp_in_addr_len = cin.addr_len;

		pi->write(out);
	} else if (!rd_in->empty()) {
		struct rab_request din;
		din = rd_in->read();

		out.type = SYSMM_REQUEST_DATA_RD;
		out.pid = 0;
		out.dp_in_addr = din.in_addr;
		out.dp_in_len = din.in_len;
		out.dp_in_size = din.in_size;

		pi->write(out);
	} else if (!wr_in->empty()) {
		struct rab_request din;
		din = wr_in->read();

		out.type = SYSMM_REQUEST_DATA_WR;
		out.pid = 0;
		out.dp_in_addr = din.in_addr;
		out.dp_in_len = din.in_len;
		out.dp_in_size = din.in_size;

		pi->write(out);
	}
}

/*
 * TODO
 * Variable-size segment table is conceptually easy to implement.
 * But its hard to have an efficient version maybe.
 */
static void parser(stream<struct pipeline_info> *input,
		   stream<struct pipeline_info> *output)
{
#pragma HLS INLINE OFF
#pragma HLS PIPELINE II=1

	struct pipeline_info pi;
	struct segvar_entry entry;

	if (input->empty())
		return;
	pi = input->read();

	switch (pi.type) {
	case SYSMM_REQUEST_CONTROL:
		pi.cp_ret = 0; 
		pi.cp_ret_addr_len = 0x10000;
		break;
	case SYSMM_REQUEST_DATA_RD:
	case SYSMM_REQUEST_DATA_WR:
		pi.dp_ret = 0;
		pi.dp_ret_addr = pi.dp_in_addr;
		break;
	};
	output->write(pi);
}

static void
disaggregate_output(stream<struct pipeline_info> *input,
		    stream<struct alloc_seg_out> *ctl_out,
		    stream<struct rab_reply> *rd_out,
		    stream<struct rab_reply> *wr_out)
{
#pragma HLS INLINE OFF
#pragma HLS PIPELINE II=1

	struct pipeline_info pi;

	if (input->empty())
		return;
	pi = input->read();

	if (pi.type == SYSMM_REQUEST_CONTROL) {
		struct alloc_seg_out out;

		out.ret = pi.cp_ret;
		out.addr_len = pi.cp_ret_addr_len;
		ctl_out->write(out);
	} else if (pi.type == SYSMM_REQUEST_DATA_RD) {
		struct rab_reply out;

		out.out_addr = pi.dp_ret_addr;
		out.drop = pi.dp_ret;
		rd_out->write(out);
	} else if (pi.type == SYSMM_REQUEST_DATA_WR) {
		struct rab_reply out;

		out.out_addr = pi.dp_ret_addr;
		out.drop = pi.dp_ret;
		wr_out->write(out);
	}
}

/*
 * ctl_in and ctl_out are for alloc() and free().
 * rd/wr_in/out are for permission checking. Since AXI-MM suppoert concurrent
 * Read and Write, thus our AXI RAB could send rd_in and wr_in at the same time.
 */
void mm_segvar_hls(stream<struct alloc_seg_in> *ctl_in, stream<struct alloc_seg_out> *ctl_out,
		   stream<struct rab_request> *rd_in, stream<struct rab_reply> *rd_out,
		   stream<struct rab_request> *wr_in, stream<struct rab_reply> *wr_out)
{
#pragma HLS DATAFLOW
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS DATA_PACK variable=ctl_int
#pragma HLS DATA_PACK variable=ctl_out
#pragma HLS DATA_PACK variable=rd_in
#pragma HLS DATA_PACK variable=rd_out
#pragma HLS DATA_PACK variable=wr_in
#pragma HLS DATA_PACK variable=wr_out

#pragma HLS INTERFACE axis port=ctl_int
#pragma HLS INTERFACE axis port=ctl_out
#pragma HLS INTERFACE axis port=rd_in
#pragma HLS INTERFACE axis port=rd_out
#pragma HLS INTERFACE axis port=wr_in
#pragma HLS INTERFACE axis port=wr_out

	static stream<struct pipeline_info> PI_input_to_parser("PI_input_to_parser");
	static stream<struct pipeline_info> PI_parser_to_output("PI_parser_output");
#pragma HLS STREAM variable=PI_input_to_parser depth=32
#pragma HLS STREAM variable=PI_parser_to_output depth=32

	aggregate_input(ctl_in, rd_in, wr_in, &PI_input_to_parser);
	parser(&PI_input_to_parser, &PI_parser_to_output);
	disaggregate_output(&PI_parser_to_output, ctl_out, rd_out, wr_out);
}
