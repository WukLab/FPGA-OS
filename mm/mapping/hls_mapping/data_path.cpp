/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#define ENABLE_PR

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
void remux(stream<struct mapping_request> *rd,
	   stream<struct mapping_request> *wr,
	   stream<struct pipeline_info> *out)
{
#pragma HLS PIPELINE

	struct mapping_request req = { 0 };

	if (!rd->empty()) {
		struct pipeline_info info = { 0 };

		req = rd->read();

		if (req.opcode == MAPPING_REQUEST_READ ||
		    req.opcode == MAPPING_REQUEST_WRITE)
			info.opcode = PI_OPCODE_GET;
		else if (req.opcode == MAPPING_SET)
			info.opcode = PI_OPCODE_SET;
		else
			info.opcode = PI_OPCODE_UNKNOWN;

		info.input = req.address;
		info.length = req.length;
		info.channel = PI_CHANNEL_READ;
		out->write(info);
	} else if (!wr->empty()) {
		struct pipeline_info info = { 0 };

		req = wr->read();

		if (req.opcode == MAPPING_REQUEST_READ ||
		    req.opcode == MAPPING_REQUEST_WRITE)
			info.opcode = PI_OPCODE_GET;
		else if (req.opcode == MAPPING_SET)
			info.opcode = PI_OPCODE_SET;
		else
			info.opcode = PI_OPCODE_UNKNOWN;
		info.input = req.address;
		info.length = req.length;
		info.channel = PI_CHANNEL_WRITE;
		out->write(info);
	}
}

/* This stage only sends command to read from BRAM. */
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
	cmd.address = index;
	cmd.length = 1;
	BRAM_rd_cmd->write(cmd);
}

/*
 * This stage will wait until we got data from BRAM.
 * - After data return, we save the whole HB, also
 *   try to find a matching slot in the HB.
 * - If and only if the OP is a GET AND there is a hit,
 *   otherwise we send commands to read from DRAM.
 */
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
		pi.hb_bram = hb;

		for (i = 0; i < NR_SLOTS_PER_BUCKET; i++) {
			if (hb((i + 1) * NR_BITS_KEY - 1, i * NR_BITS_KEY) == pi.input) {
				hit = true;
				pi.slot = i;
				pi.output_status = 0;
				pi.output = hb((i + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					       i * NR_BITS_VAL + NR_BITS_VAL_OFF);
			}
		}

		if (hit)
			pi.pi_state = PI_STATE_HIT_BRAM;
		else
			pi.pi_state = PI_STATE_MISS_BRAM;

		if (!(hit && pi.opcode == PI_OPCODE_GET)) {
			cmd.address = pi.hash(NR_HT_BUCKET_DRAM_SHIFT - 1, 0);
			cmd.length = 1;
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
 * TODO:
 * If this function fail to find an avaiable slot,
 * we will just return spot 0 now.
 *
 * In theory:
 * - For BRAM ht, this is okay, we can kick out somehthing.
 * - For DRAM ht, we should use chaining.
 */
static inline int find_empty_slot(ap_uint<NR_SLOTS_PER_BUCKET> in)
{
#pragma HLS INLINE
	int i = 0, slot = 0;
	for (i = 0; i < NR_SLOTS_PER_BUCKET; i++) {
		if (in(i+1, i) == 0) {
			slot = i;
			break;
		}
	}
	return slot;
}

void fill_S2(stream<struct pipeline_info> *pi_in,
	     stream<struct pipeline_info> *pi_out,
	     stream<struct mem_cmd>		*DRAM_wr_cmd,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*DRAM_wr_data,
	     stream<struct mem_cmd>		*BRAM_wr_cmd,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*BRAM_wr_data)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	struct pipeline_info pi = { 0 };

	if (!pi_in->empty()) {
		pi = pi_in->read();

		if (pi.opcode == PI_OPCODE_SET) {
			/*
			 * Write back to BRAM
			 */
			int slot_b = 0;
			struct mem_cmd cmd_b = { 0 };
			if ((pi.pi_state & PI_STATE_HIT_BRAM) == PI_STATE_HIT_BRAM) {
				/* Replace existing matched slot */
				slot_b = pi.slot;
			} else {
				/*
				 * Find a new slot if any.
				 * Otherwise it will override existing un-matched slot.
				 */
				slot_b = find_empty_slot(pi.hb_bram(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
								    NR_BITS_BITMAP_OFF));
				pi.hb_bram(NR_BITS_BITMAP_OFF + slot_b,
					   NR_BITS_BITMAP_OFF + slot_b) = 1;
			}

			pi.hb_bram((slot_b + 1) * NR_BITS_KEY - 1, slot_b * NR_BITS_KEY) = pi.input;
			pi.hb_bram((slot_b + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
				   slot_b * NR_BITS_VAL + NR_BITS_VAL_OFF) = pi.length;
			cmd_b.address = pi.hash(NR_HT_BUCKET_BRAM_SHIFT - 1, 0);
			cmd_b.length = 1;
			BRAM_wr_cmd->write(cmd_b);
			BRAM_wr_data->write(pi.hb_bram);

			/*
			 * Write back to DRAM
			 */
			int slot_d = 0;
			struct mem_cmd cmd_d = { 0 };
			if ((pi.pi_state & PI_STATE_HIT_DRAM) == PI_STATE_HIT_DRAM) {
				/* Replace existing matched slot */
				slot_d = pi.slot_dram;
			} else {
				/*
				 * XXX
				 * Find a new slot if any.
				 * Currently, we override. Ideally, should chain.
				 */
				slot_d = find_empty_slot(pi.hb_dram(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
								    NR_BITS_BITMAP_OFF));

				pi.hb_dram(NR_BITS_BITMAP_OFF + slot_d,
					   NR_BITS_BITMAP_OFF + slot_d) = 1;
			}

			pi.hb_dram((slot_d + 1) * NR_BITS_KEY - 1, slot_d * NR_BITS_KEY) = pi.input;
			pi.hb_dram((slot_d + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
				   slot_d * NR_BITS_VAL + NR_BITS_VAL_OFF) = pi.length;
			cmd_d.address = pi.hash(NR_HT_BUCKET_DRAM_SHIFT - 1, 0);
			cmd_d.length = 1;
			DRAM_wr_cmd->write(cmd_d);
			DRAM_wr_data->write(pi.hb_dram);

			pi_out->write(pi);
		} else if (pi.opcode == PI_OPCODE_GET) {
			if (((pi.pi_state & PI_STATE_MISS_BRAM) == PI_STATE_MISS_BRAM) &&
			     (pi.pi_state & PI_STATE_HIT_DRAM) == PI_STATE_HIT_DRAM) {
				/*
				 * The case where we miss on BRAM but hit on
				 * DRAM. We need write the new pair into BRAM.
				 */
				int slot_b = 0;
				struct mem_cmd cmd_b = { 0 };

				slot_b = find_empty_slot(pi.hb_bram(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
								    NR_BITS_BITMAP_OFF));

				/* Copy the data from the cached DRAM HB */
				pi.hb_bram(NR_BITS_BITMAP_OFF + slot_b, NR_BITS_BITMAP_OFF + slot_b) = 1;

				pi.hb_bram((slot_b + 1) * NR_BITS_KEY - 1,
					    slot_b * NR_BITS_KEY) = pi.hb_dram((pi.slot_dram + 1) * NR_BITS_KEY - 1,
					   					pi.slot_dram * NR_BITS_KEY);

				pi.hb_bram((slot_b + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					    slot_b * NR_BITS_VAL + NR_BITS_VAL_OFF) = pi.hb_bram((pi.slot_dram + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					    							  pi.slot_dram * NR_BITS_VAL + NR_BITS_VAL_OFF);

				cmd_b.address = pi.hash(NR_HT_BUCKET_BRAM_SHIFT - 1, 0);
				cmd_b.length = 1;
				BRAM_wr_cmd->write(cmd_b);
				BRAM_wr_data->write(pi.hb_bram);

				pi_out->write(pi);
			} else {
				pi_out->write(pi);
			}
		} else {
			/* Save for future operations */
			pi_out->write(pi);
		}
	}
}

void fill_S1(stream<struct pipeline_info>	*pi_in,
	     stream<struct pipeline_info>	*pi_out,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*DRAM_rd_data)
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
		if (pi.opcode == PI_OPCODE_GET &&
		    pi.pi_state == PI_STATE_HIT_BRAM) {
			pi_out->write(pi);
			break;
		}
		state = FILL_READ_DATA;
		break;
	case FILL_READ_DATA:
		ap_uint<MEM_BUS_WIDTH> hb = 0;
		int i = 0, index = 0;
		bool hit = false;

		if (DRAM_rd_data->empty())
			break;
		hb = DRAM_rd_data->read();
		pi.hb_dram = hb;

		/* Check if the DRAM HB has the key */
		for (i = 0; i < NR_SLOTS_PER_BUCKET; i++) {
			if (hb((i + 1) * NR_BITS_KEY - 1, i * NR_BITS_KEY) == pi.input) {
				hit = true;
				pi.slot_dram = i;
				pi.output_status = 0;
				pi.output = hb((i + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					       i * NR_BITS_VAL + NR_BITS_VAL_OFF);
			}
		}

		if (hit) {
			pi.pi_state |= PI_STATE_HIT_DRAM;
		} else {
			/*
			 * XXX
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
			pi.pi_state |= PI_STATE_MISS_DRAM;
			pi.output = 0;
			pi.output_status = 1;
		}
		pi_out->write(pi);
		state = FILL_IDLE;
		break;
	}
}

void demux(stream<struct pipeline_info> *pi_in,
	   stream<struct mapping_reply> *rd_reply,
	   stream<struct mapping_reply> *wr_reply)
{
#pragma HLS PIPELINE

	struct mapping_reply reply = { 0 };
	struct pipeline_info pi = { 0 };

	if (!pi_in->empty()) {
		pi = pi_in->read();

		reply.address = pi.output;
		reply.status = pi.output_status;
		if (pi.channel == PI_CHANNEL_READ)
			rd_reply->write(reply);
		else if (pi.opcode == MAPPING_REQUEST_WRITE)
			wr_reply->write(reply);
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
void data_path(stream<struct mapping_request> *rd_request,
	       stream<struct mapping_request> *wr_request,
	       stream<struct mapping_reply> *rd_reply,
	       stream<struct mapping_reply> *wr_reply,

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

#pragma HLS STREAM variable=PI_pipeline_info		depth=256
#pragma HLS STREAM variable=PI_hash_to_compare		depth=256
#pragma HLS STREAM variable=PI_compare_to_fillS1	depth=256
#pragma HLS STREAM variable=PI_fillS1_to_fillS2		depth=256
#pragma HLS STREAM variable=PI_fillS2_to_out		depth=256

	remux(rd_request, wr_request, &PI_pipeline_info);

	compute_hash(&PI_pipeline_info, &PI_hash_to_compare);

	compare_bram_ht(&PI_hash_to_compare, &PI_compare_to_fillS1,
			BRAM_rd_cmd, BRAM_rd_data, DRAM_rd_cmd);

	fill_S1(&PI_compare_to_fillS1, &PI_fillS1_to_fillS2, DRAM_rd_data);

	fill_S2(&PI_fillS1_to_fillS2, &PI_fillS2_to_out,
		DRAM_wr_cmd, DRAM_wr_data,
		BRAM_wr_cmd, BRAM_wr_data);

	demux(&PI_fillS2_to_out, rd_reply, wr_reply);
}
