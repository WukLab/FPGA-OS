/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/kernel.h>
#include <string.h>
#include "top.hpp"
#include "dm.hpp"
#include "hash.hpp"

using namespace hls;

/*
 * Forge incoming requets into internal pipeline
 * words. Should at the top level.
 */
void remux(stream<struct paging_request> *rd,
	   stream<struct paging_request> *wr,
	   stream<struct pipeline_info> *out)
{
#pragma HLS PIPELINE

	struct paging_request req = { 0 };

	if (!rd->empty()) {
		struct pipeline_info info = { 0 };

		req = rd->read();
		info.input = req.address;
		info.length = req.length;
		info.opcode = req.opcode;
		out->write(info);
	} else if (!wr->empty()) {
		struct pipeline_info info = { 0 };

		req = wr->read();
		info.input = req.address;
		info.length = req.length;
		info.opcode = req.opcode;
		out->write(info);
	}
}

void read_bram(stream<struct pipeline_info> *pi_in,
	       stream<struct pipeline_info> *pi_out,
	       stream<struct mem_cmd> *BRAM_rd_cmd)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

	struct pipeline_info pi = { 0 };
	struct mem_cmd cmd = { 0 };
	int index = 0;

	if (pi_in->empty())
		return;

	pi = pi_in->read();
	pi_out->write(pi);

	index = pi.hash(NR_HT_BUCKET_BRAM_SHIFT - 1, 0);

	/*
	 * Send commands to read from BRAM
	 * BRAM addressing mode:
	 */
	cmd.address = index;
	cmd.length = 1;
	BRAM_rd_cmd->write(cmd);
}

void compare_bram(stream<struct pipeline_info> *pi_in,
		  stream<struct pipeline_info> *pi_out,
		  stream<ap_uint<MEM_BUS_WIDTH> > *BRAM_rd_data,
		  stream<struct mem_cmd> *DRAM_rd_cmd)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

	struct pipeline_info pi = { 0 };
	ap_uint<MEM_BUS_WIDTH> hb = 0;
	struct mem_cmd cmd = { 0 };
	int i = 0;
	bool hit = false;

	/* Wait until we received data from BRAM */
	if (!pi_in->empty() && !BRAM_rd_data->empty()) {
		pi = pi_in->read();
		hb = BRAM_rd_data->read();

		for (i = 0; i < NR_SLOTS_PER_BUCKET; i++) {
			if (hb((i + 1) * NR_BITS_KEY - 1, i * NR_BITS_KEY) == pi.input) {
				hit = true;
				pi.output_status = 0;
				pi.output = hb((i + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					       i * NR_BITS_VAL + NR_BITS_VAL_OFF);
			}
		}

		if (hit) {
			pi.pi_state = PI_STATE_HIT;
		} else {
			pi.pi_state = PI_STATE_MISS;

			/*
			 * Send requests to DRAM
			 * to read the corresponding bucket
			 * DRAM addressing mode:
			 */
			cmd.address = pi.hash(NR_HT_BUCKET_DRAM_SHIFT - 1, 0);
			cmd.length = NR_BITS_BUCKET / 8;
			DRAM_rd_cmd->write(cmd);
		}
		pi_out->write(pi);
	}
}

void compare_bram_ht(stream<struct pipeline_info> *pi_in,
		     stream<struct pipeline_info> *pi_out,
		     stream<struct mem_cmd> *BRAM_rd_cmd,
		     stream<ap_uint<MEM_BUS_WIDTH> > *BRAM_rd_data,
		     stream<struct mem_cmd> *DRAM_rd_cmd)
{
#pragma HLS INLINE

	static stream<struct pipeline_info> PI_1;
#pragma HLS STREAM variable=PI_1 depth=256	// Depends on BRAM latency

	read_bram(pi_in, &PI_1, BRAM_rd_cmd);
	compare_bram(&PI_1, pi_out, BRAM_rd_data, DRAM_rd_cmd);
}

enum FILL_STATES {
	FILL_IDLE,
	FILL_READ_DATA,
};

/*
 * The second step of fill.
 * Data was retrived from DRAM and saved to BRAM.
 * We another round of translation using the fresh data.
 */
void fill_S2(stream<struct pipeline_info> *pi_in,
	     stream<struct pipeline_info> *pi_out,
	     stream<ap_uint<MEM_BUS_WIDTH> > *hb_in)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	struct pipeline_info pi = { 0 };
	int index = 0, i = 0;
	bool hit = false;
	ap_uint<MEM_BUS_WIDTH> hb;

	if (!pi_in->empty()) {
		pi = pi_in->read();

		if (pi.pi_state != PI_STATE_HIT) {
			hb = hb_in->read();
			for (i = 0; i < NR_SLOTS_PER_BUCKET; i++) {
				if (hb((i + 1) * NR_BITS_KEY - 1, i * NR_BITS_KEY) == pi.input) {
					hit = true;
					pi.output_status = 0;
					pi.output = hb((i + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
						       i * NR_BITS_VAL + NR_BITS_VAL_OFF);
				}
			}

			if (hit) {
				pi.pi_state = PI_STATE_HIT;
			} else {
				/*
				 * If we are here, it means we even
				 * can not find the key on the DRAM bucket.
				 * Causes:
				 * 1) DRAM is empty
				 * 2) chained (not implemented),
				 * 3) BUG
				 *
				 * If DRAM is empty, all requests other than 0
				 * will come to here.
				 */
				pi.output = 0;
				pi.output_status = 1;
			}
		}
		pi_out->write(pi);
	}
}

/*
 * XXX
 * The fetched DRAM hash bucket is now used to override
 * the whole corresponding BRAM hash bucket.
 * A more ideal case is: 1) Find an empty slot within
 * the BRAM hash bucket, 2) Just fill this one slot
 * using the DRAM hash slot. This is too complex for fow.
 */
void fill_S1(stream<struct pipeline_info>	*pi_in,
	     stream<struct pipeline_info>	*pi_out,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*DRAM_rd_data,
	     stream<struct mem_cmd>		*BRAM_wr_cmd,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*BRAM_wr_data,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*hb_out)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	static struct pipeline_info pi = { 0 };
	static enum FILL_STATES state = FILL_IDLE;

	switch (state) {
	case FILL_IDLE:
		if (pi_in->empty())
			break;

		pi = pi_in->read();
		if (pi.pi_state == PI_STATE_HIT) {
			pi_out->write(pi);
			break;
		}
		state = FILL_READ_DATA;
		break;
	case FILL_READ_DATA:
		ap_uint<MEM_BUS_WIDTH> hb = 0;
		struct mem_cmd cmd = { 0 };
		int index = 0;

		if (DRAM_rd_data->empty())
			break;
		hb = DRAM_rd_data->read();

		/*
		 * Perform BRAM Write
		 */
		index = pi.hash(NR_HT_BUCKET_BRAM_SHIFT - 1, 0);
		cmd.address = index;
		cmd.length = 1;
		BRAM_wr_cmd->write(cmd);
		BRAM_wr_data->write(hb);

		pi_out->write(pi);
		hb_out->write(hb);
		state = FILL_IDLE;
		break;
	}
}

void demux(stream<struct pipeline_info> *pi_in,
	   stream<struct paging_reply> *rd_reply,
	   stream<struct paging_reply> *wr_reply,
	   stream<struct mem_cmd>		*DRAM_wr_cmd,
	   stream<ap_uint<MEM_BUS_WIDTH> >	*DRAM_wr_data)
{
#pragma HLS PIPELINE

	struct paging_reply reply = { 0 };
	struct pipeline_info pi = { 0 };

	if (!pi_in->empty()) {
		pi = pi_in->read();

		reply.address = pi.output;
		reply.status = pi.output_status;
		if (pi.opcode == MAPPING_REQUEST_READ)
			rd_reply->write(reply);
		else if (pi.opcode == MAPPING_REQUEST_WRITE) {
			wr_reply->write(reply);

			//XXX remove this
			struct mem_cmd cmd;
			ap_uint<MEM_BUS_WIDTH> data;
			DRAM_wr_cmd->write(cmd);
			DRAM_wr_data->write(data);
		}
	}
}

/*
 * I @rd_request: translation request for AXI read
 * I @wr_request: translation request for AXI write
 * O @rd_reply: translation reply for read
 * O @wr_reply: translation reply for write
 * O @read_cmd: commands to do memory read
 * I @read_data: data of memory read.
 * O @write_cmd: commands to do memory write
 * O @write_data: data to write
 */
void data_path(stream<struct paging_request> *rd_request,
	       stream<struct paging_request> *wr_request,
	       stream<struct paging_reply> *rd_reply,
	       stream<struct paging_reply> *wr_reply,

	       stream<struct mem_cmd>		*DRAM_rd_cmd,
	       stream<struct mem_cmd>		*DRAM_wr_cmd,
	       stream<ap_uint<MEM_BUS_WIDTH> >	*DRAM_rd_data,
	       stream<ap_uint<MEM_BUS_WIDTH> >	*DRAM_wr_data,

	       stream<struct mem_cmd>		*BRAM_rd_cmd,
	       stream<struct mem_cmd>		*BRAM_wr_cmd,
	       stream<ap_uint<MEM_BUS_WIDTH> >	*BRAM_rd_data,
	       stream<ap_uint<MEM_BUS_WIDTH> >	*BRAM_wr_data)
{
#pragma HLS INLINE
#pragma HLS INTERFACE ap_ctrl_none port=return

	static stream<struct pipeline_info> PI_pipeline_info("PI_pipeline_info");
	static stream<struct pipeline_info> PI_hash_to_compare("PI_hash_to_compare");
	static stream<struct pipeline_info> PI_compare_to_fillS1("PI_compare_to_fillS1");
	static stream<struct pipeline_info> PI_fillS1_to_fillS2("PI_fillS1_to_fillS2");
	static stream<struct pipeline_info> PI_fillS2_to_out("PI_fill_to_out");

	static stream<ap_uint<MEM_BUS_WIDTH> > HB_fillS1_to_fillS2("HB_fillS1_to_fillS2");

#pragma HLS STREAM variable=PI_pipeline_info		depth=256
#pragma HLS STREAM variable=PI_hash_to_compare		depth=256
#pragma HLS STREAM variable=PI_compare_to_fillS1	depth=256
#pragma HLS STREAM variable=PI_fillS1_to_fillS2		depth=256
#pragma HLS STREAM variable=PI_fillS2_to_out		depth=256
#pragma HLS STREAM variable=HB_fillS1_to_fillS2		depth=256

	remux(rd_request, wr_request, &PI_pipeline_info);

	compute_hash(&PI_pipeline_info, &PI_hash_to_compare);

	compare_bram_ht(&PI_hash_to_compare, &PI_compare_to_fillS1,
			BRAM_rd_cmd, BRAM_rd_data, DRAM_rd_cmd);

	fill_S1(&PI_compare_to_fillS1, &PI_fillS1_to_fillS2,
		DRAM_rd_data,
		BRAM_wr_cmd, BRAM_wr_data, &HB_fillS1_to_fillS2);

	fill_S2(&PI_fillS1_to_fillS2, &PI_fillS2_to_out, &HB_fillS1_to_fillS2);

	demux(&PI_fillS2_to_out, rd_reply, wr_reply, DRAM_wr_cmd, DRAM_wr_data);
}
