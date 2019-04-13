/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/kernel.h>
#include <fpga/axis_mapping.h>
#include "../hls_mapping/hash.hpp"
#include "../hls_mapping/dm.hpp"


void bram_hashtable(hls::stream<struct dm_cmd>		*BRAM_rd_cmd,
		    hls::stream<struct dm_cmd>		*BRAM_wr_cmd,
		    hls::stream<struct axis_mem>	*BRAM_rd_data,
		    hls::stream<struct axis_mem>	*BRAM_wr_data,
		    hls::stream<ap_uint<8> >		*BRAM_rd_status,
		    hls::stream<ap_uint<8> >		*BRAM_wr_status)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS PIPELINE

#pragma HLS INTERFACE axis both port=BRAM_rd_cmd
#pragma HLS INTERFACE axis both port=BRAM_wr_cmd
#pragma HLS INTERFACE axis both port=BRAM_rd_data
#pragma HLS INTERFACE axis both port=BRAM_wr_data
#pragma HLS INTERFACE axis both port=BRAM_rd_status
#pragma HLS INTERFACE axis both port=BRAM_wr_status

#pragma HLS DATA_PACK variable=BRAM_rd_cmd
#pragma HLS DATA_PACK variable=BRAM_wr_cmd

	static ap_uint<NR_BITS_HASH> ht_bram[NR_HT_BUCKET_BRAM];
#pragma HLS ARRAY_PARTITION variable=ht_bram complete dim=1

	if (!BRAM_rd_cmd->empty()) {
		struct axis_mem data = { 0 };
		struct dm_cmd cmd = { 0 };
		ap_uint<32> index;
		ap_uint<8> status;

		cmd = BRAM_rd_cmd->read();
		index = cmd.start_address;

		PR("BRAM rd index=%d\n", index.to_uint());
		data.data = ht_bram[index];
		data.keep = 0xFFFFFFFFFFFFFFFF;
		data.last = 1;
		BRAM_rd_data->write(data);
		BRAM_rd_status->write(status);
	}

	if (!BRAM_wr_cmd->empty() && !BRAM_wr_data->empty()) {
		struct axis_mem data = { 0 };
		struct dm_cmd cmd = { 0 };
		ap_uint<32> index;
		ap_uint<8> status;

		cmd = BRAM_wr_cmd->read();
		data = BRAM_wr_data->read();
		index = cmd.start_address;

		PR("BRAM wr index=%d data=%x\n", index.to_uint(), data.data.to_uint());
		ht_bram[index] = data.data;

		BRAM_wr_status->write(status);
	}
}
