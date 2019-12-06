/*
 * Copyright (c) 2019，Wuklab, UCSD.
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
#include "resv_table.hpp"

using namespace hls;

extern ap_uint<PA_WIDTH> mapping_table_addr_base;

/*
 * Forge incoming requets into internal pipeline
 * words. Should at the top level.
 */
void remux(stream<struct mapping_request> *rd,
	   stream<struct mapping_request> *wr,
	   stream<struct pipeline_info> *out)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	if (!rd->empty()) {
		struct pipeline_info info = { 0 };
		struct mapping_request req = { 0 };

		req = rd->read();

		if (req.opcode == MAPPING_REQUEST_READ)
			info.opcode = PI_OPCODE_GET | PI_PERM_R;
		else if (req.opcode == MAPPING_REQUEST_WRITE)
			info.opcode = PI_OPCODE_GET | PI_PERM_RW;
		else if (req.opcode == (MAPPING_SET | MAPPING_PERMISSION_R))
			info.opcode = PI_OPCODE_SET | PI_PERM_R;
		else if (req.opcode == (MAPPING_SET | MAPPING_PERMISSION_RW))
			info.opcode = PI_OPCODE_SET | PI_PERM_RW;
		else
			info.opcode = PI_OPCODE_UNKNOWN;

		info.input = req.address;
		info.length = req.length;
		info.channel = PI_CHANNEL_READ;
		out->write(info);
	} else if (!wr->empty()) {
		struct pipeline_info info = { 0 };
		struct mapping_request req = { 0 };

		req = wr->read();

		if (req.opcode == MAPPING_REQUEST_READ)
			info.opcode = PI_OPCODE_GET | PI_PERM_R;
		else if (req.opcode == MAPPING_REQUEST_WRITE)
			info.opcode = PI_OPCODE_GET | PI_PERM_RW;
		else if (req.opcode == (MAPPING_SET | MAPPING_PERMISSION_R))
			info.opcode = PI_OPCODE_SET | PI_PERM_R;
		else if (req.opcode == (MAPPING_SET | MAPPING_PERMISSION_RW))
			info.opcode = PI_OPCODE_SET | PI_PERM_RW;
		else
			info.opcode = PI_OPCODE_UNKNOWN;
		info.input = req.address;
		info.length = req.length;
		info.channel = PI_CHANNEL_WRITE;
		out->write(info);
	}
}

enum READ_BRAM_STATE {
	READ_BRAM_IDLE,
	READ_BRAM_ADDR_CHECK,
	READ_BRAM_ADDR_RESP
};

/* This stage only sends command to read from BRAM. */
void read_bram(stream<struct pipeline_info>	*pi_in,
	       stream<struct pipeline_info>	*pi_out,
	       stream<struct mem_cmd>		*BRAM_rd_cmd,
	       stream<struct table_request>	*addr_resv_req,
	       stream<ap_uint<2> >		*addr_resv_res)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	static enum READ_BRAM_STATE state = READ_BRAM_IDLE;
	static struct pipeline_info pi = { 0 };		
	static ap_uint<NR_HT_BUCKET_BRAM_SHIFT> index = 0;

	switch (state) {
	case READ_BRAM_IDLE:
		if (!pi_in->empty()) {
			pi = pi_in->read();
			pi_out->write(pi);

			index = pi.hash(NR_HT_BUCKET_BRAM_SHIFT - 1, 0);
			state = READ_BRAM_ADDR_CHECK;
		}
		break;
	case READ_BRAM_ADDR_CHECK: {
		struct table_request req = { RESV, index };
		addr_resv_req->write(req);
		state = READ_BRAM_ADDR_RESP;
		break;
	}
	case READ_BRAM_ADDR_RESP:
		if (!addr_resv_res->empty()) {
			ap_uint<2> res = addr_resv_res->read();
			if (res != RESV_SUCCESS) {
				state = READ_BRAM_ADDR_CHECK;
				break;
			} else {
				state = READ_BRAM_IDLE;
				struct mem_cmd cmd = { 0 };
				cmd.address = index;
				cmd.length = 1;
				BRAM_rd_cmd->write(cmd);
			}
		}
		break;
	}
}

static int __compare(ap_uint<512> hb, ap_uint<32> input)
{
#pragma HLS INLINE
#if 1
	int i = NR_SLOTS_PER_BUCKET;
	for (i = 0; i < NR_SLOTS_PER_BUCKET; i++) {
		if (hb((i + 1) * NR_BITS_KEY - 1, i * NR_BITS_KEY) ==
		    input(NR_BITS_KEY - 1, 0)) {
			break;
		}
	}
	return i;
#else
	if (hb(31,0) == input)
		return 0;
	else
		return 7;
#endif
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
		  stream<ap_uint<MEM_BUS_WIDTH> > *BRAM_rd_data)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	/* Wait until we received data from BRAM */
	if (!pi_in->empty() && !BRAM_rd_data->empty()) {
		struct pipeline_info pi = { 0 };
		ap_uint<MEM_BUS_WIDTH> hb = 0;
		int i;
		bool hit;

		pi = pi_in->read();
		hb = BRAM_rd_data->read();
		pi.hb_bram = hb;

		i = __compare(hb, pi.input);
		if (i < NR_SLOTS_PER_BUCKET)
			hit = true;
		else
			hit = false;

		if (hit) {
			pi.pi_state = PI_STATE_HIT_BRAM;
			if (pi.opcode(PI_OPCODE_WIDTH - 1, 0) == PI_OPCODE_GET &&
			    (pi.opcode[7] & (!hb[NR_BITS_PERM_OFF + i]))) {
				pi.pi_state = pi.pi_state | PI_STATE_NO_PERM;
				pi.slot = 0;
				pi.output_status = PI_OUTPUT_FAILURE;
				pi.output = 0;
			} else {
				pi.slot = i;
				pi.output_status = PI_OUTPUT_SUCCEED;
				pi.output = hb((i + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					       i * NR_BITS_VAL + NR_BITS_VAL_OFF);
			}
		} else {
			pi.pi_state = PI_STATE_MISS_BRAM;
			pi.slot = 0;
			pi.output_status = PI_OUTPUT_FAILURE;
			pi.output = 0;
		}
/* leave sending cmd to next part */
#if 0
		if (!(pi.opcode == PI_OPCODE_GET && hit)) {
			/*
			 * Three cases walk into here:
			 * SET + HIT
			 * SET + MISS
			 * GET + MISS
			 */
			struct mem_cmd cmd = { 0 };
			cmd.address = pi.hash(NR_HT_BUCKET_DRAM_SHIFT - 1, 0);
			cmd.length = 1;
			DRAM_rd_cmd->write(cmd);
		}
#endif
		pi_out->write(pi);
	}
}

void compare_bram_ht(stream<struct pipeline_info> *pi_in,
		     stream<struct pipeline_info> *pi_out,
		     stream<struct mem_cmd> *BRAM_rd_cmd,
		     stream<ap_uint<MEM_BUS_WIDTH> > *BRAM_rd_data,
		     stream<struct table_request>	*addr_resv_req,
		     stream<ap_uint<2> >		*addr_resv_res)
{
#pragma HLS INLINE

	static stream<struct pipeline_info> PI_1;
#pragma HLS STREAM variable=PI_1 depth=256	// Depends on BRAM latency

	read_bram(pi_in, &PI_1, BRAM_rd_cmd, addr_resv_req, addr_resv_res);
	compare_bram(&PI_1, pi_out, BRAM_rd_data);
}

enum FILL_STATES {
	FILL_IDLE,
	FILL_READ_DATA,
	FILL_SEND_CMD
};

enum ALLOC_STATES {
	ALLOC_IDLE,
	ALLOC_RECV_RET,
	ALLOC_WRITE_DATA
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
		if (in[i] == 0) {
			slot = i;
			break;
		}
	}
	PR("Slot: %d\n", slot);
	return slot;
}

static inline int find_empty_slot_dram(ap_uint<NR_SLOTS_PER_BUCKET> in)
{
#pragma HLS INLINE
	int i = 0, slot = -1;
	for (i = 0; i < NR_SLOTS_PER_BUCKET; i++) {
		if (in[i] == 0) {
			slot = i;
			break;
		}
	}
	PR("Slot: %d\n", slot);
	return slot;
}

void fill_S2(stream<struct pipeline_info> *pi_in,
	     stream<struct pipeline_info> *pi_out,
	     stream<struct mem_cmd>		*DRAM_wr_cmd,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*DRAM_wr_data,
	     stream<struct mem_cmd>		*BRAM_wr_cmd,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*BRAM_wr_data,
	     hls::stream<struct buddy_alloc_if>	*alloc,
	     hls::stream<struct buddy_alloc_ret_if>	*alloc_ret)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	static struct pipeline_info pi = { 0 };
	static enum ALLOC_STATES state = ALLOC_IDLE;
	struct buddy_alloc_ret_if alloc_resp = { 0 };
	static struct mem_cmd cmd_d = { 0 };
	static ap_uint<NR_BITS_BUCKET> new_hb_dram = 0;

	switch(state) {
	case ALLOC_IDLE:
		if (!pi_in->empty()) {
			pi = pi_in->read();
			if (pi.opcode(PI_OPCODE_WIDTH - 1, 0) == PI_OPCODE_SET) {
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
					 *
					 * Since BRAM HT is not using any chaining,
					 * it's OKAY to override by design.
					 */
					slot_b = find_empty_slot(pi.hb_bram(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
									NR_BITS_BITMAP_OFF));
					pi.hb_bram[NR_BITS_BITMAP_OFF + slot_b] = 1;
				}

				pi.hb_bram((slot_b + 1) * NR_BITS_KEY - 1, slot_b * NR_BITS_KEY) = pi.input;
				pi.hb_bram((slot_b + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					slot_b * NR_BITS_VAL + NR_BITS_VAL_OFF) = pi.length;
				pi.hb_bram[NR_BITS_PERM_OFF + slot_b] = pi.opcode[7];
				cmd_b.address = pi.hash(NR_HT_BUCKET_BRAM_SHIFT - 1, 0);
				cmd_b.length = 1;
				BRAM_wr_cmd->write(cmd_b);
				BRAM_wr_data->write(pi.hb_bram);

				/*
				 * Write back to DRAM
				 */
				int slot_d = pi.slot_dram;

				/*
				 * slot_d == -1 means not hit and no empty slot.
				 * slot_d >= 0 means hit or have empty slot
				 */
				if (slot_d == -1) {
					/* generate content for new bucket */
					new_hb_dram = 0;
					new_hb_dram[NR_BITS_BITMAP_OFF] = 1;
					new_hb_dram(NR_BITS_KEY - 1, 0) = pi.input;
					new_hb_dram(NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
						    NR_BITS_VAL_OFF) = pi.length;
					new_hb_dram[NR_BITS_PERM_OFF] = pi.opcode[7];
					PR("Need to allocate new bucket.\n");
					struct buddy_alloc_if alloc_req = { 0 };
					alloc_req.opcode = BUDDY_ALLOC;
					alloc_req.order = 0;  // allocate 64 bytes
					alloc->write(alloc_req);
					state = ALLOC_RECV_RET;
					break;
				}

				pi.hb_dram[NR_BITS_BITMAP_OFF + slot_d] = 1;
				pi.hb_dram((slot_d + 1) * NR_BITS_KEY - 1, slot_d * NR_BITS_KEY) =
					pi.input;
				pi.hb_dram((slot_d + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					   slot_d * NR_BITS_VAL + NR_BITS_VAL_OFF) = pi.length;
				pi.hb_dram[NR_BITS_PERM_OFF + slot_d] = pi.opcode[7];

				state = ALLOC_WRITE_DATA;
				break;
			} else if (pi.opcode(PI_OPCODE_WIDTH - 1, 0) == PI_OPCODE_GET) {
				if (((pi.pi_state & PI_STATE_MISS_BRAM) == PI_STATE_MISS_BRAM) &&
				    (pi.pi_state & PI_STATE_HIT_DRAM) == PI_STATE_HIT_DRAM) {
					/*
					 * The case where we miss on BRAM but hit on
					 * DRAM. We need write the new pair into BRAM,
					 * even if permission check failed.
					 */
					int slot_b = 0;
					struct mem_cmd cmd_b = { 0 };

					slot_b = find_empty_slot(pi.hb_bram(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
									NR_BITS_BITMAP_OFF));

					PR(" *** MISS bram, hit DRAM, replace slot: %d\n", slot_b);
					/* Copy the data from the cached DRAM HB */
					pi.hb_bram(NR_BITS_BITMAP_OFF + slot_b,
						NR_BITS_BITMAP_OFF + slot_b) = 1;

					pi.hb_bram((slot_b + 1) * NR_BITS_KEY - 1,
						slot_b * NR_BITS_KEY) = pi.hb_dram((pi.slot_dram + 1) * NR_BITS_KEY - 1,
											pi.slot_dram * NR_BITS_KEY);

					pi.hb_bram((slot_b + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
						slot_b * NR_BITS_VAL + NR_BITS_VAL_OFF) = pi.hb_dram((pi.slot_dram + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
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
		break;
	case ALLOC_RECV_RET:
		if (alloc_ret->empty())
			break;
		alloc_resp = alloc_ret->read();
		if (alloc_resp.stat == BUDDY_SUCCESS) {
			state = ALLOC_WRITE_DATA;
			ap_uint<PA_WIDTH> alloc_addr_trans =
				(alloc_resp.addr - mapping_table_addr_base) >>
				(PA_WIDTH - NR_BITS_CHAIN_ADDR);  // transform physical addr
			pi.hb_dram[NR_BITS_CHAIN_FLAG_OFF] = 1;
			pi.hb_dram(NR_BITS_CHAIN_ADDR_OFF + NR_BITS_CHAIN_ADDR - 1,
				   NR_BITS_CHAIN_ADDR_OFF) =
				alloc_addr_trans(
					NR_BITS_CHAIN_ADDR - 1,
					0); // set chaining addr and flag on previous bucket
			cmd_d.address = alloc_addr_trans;
			cmd_d.length = 1;
			DRAM_wr_cmd->write(cmd_d);
			DRAM_wr_data->write(new_hb_dram);
		} else {
			pi.output_status = PI_OUTPUT_FAILURE;
			pi_out->write(pi);
			state = ALLOC_IDLE;
		}
		break;
	case ALLOC_WRITE_DATA:
		cmd_d.address = pi.hb_dram_addr;
		cmd_d.length = 1;
		DRAM_wr_cmd->write(cmd_d);
		DRAM_wr_data->write(pi.hb_dram);
		pi.output_status = PI_OUTPUT_SUCCEED;
		pi_out->write(pi);
		state = ALLOC_IDLE;
		break;
	}
}

void fill_S1(stream<struct pipeline_info>	*pi_in,
	     stream<struct pipeline_info>	*pi_out,
	     stream<struct mem_cmd>		*DRAM_rd_cmd,
	     stream<ap_uint<MEM_BUS_WIDTH> >	*DRAM_rd_data)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	static struct pipeline_info pi = { 0 };
	static enum FILL_STATES state = FILL_IDLE;
	static struct mem_cmd cmd = { 0 };
	static bool slot_dram_found = false;

	switch (state) {
	case FILL_IDLE:
		if (pi_in->empty())
			break;
		pi = pi_in->read();
		if (pi.opcode(PI_OPCODE_WIDTH - 1, 0) == PI_OPCODE_GET &&
		    pi.pi_state == PI_STATE_HIT_BRAM) {
			pi_out->write(pi);
			break;
		}
		cmd.address = pi.hash(NR_HT_BUCKET_DRAM_SHIFT - 1, 0);
		cmd.length = 1;
		slot_dram_found = false;
		state = FILL_SEND_CMD;
		break;
	case FILL_SEND_CMD:
		/* read chaining bucket */
		DRAM_rd_cmd->write(cmd);
		state = FILL_READ_DATA;
		break;
	case FILL_READ_DATA:
		ap_uint<MEM_BUS_WIDTH> hb = 0;
		int i ;
		bool hit;

		if (DRAM_rd_data->empty())
			break;
		hb = DRAM_rd_data->read();

		i = __compare(hb, pi.input);
		if (i < NR_SLOTS_PER_BUCKET)
			hit = true;
		else
			hit = false;

		if (hit) {
			state = FILL_IDLE;
			pi.pi_state = pi.pi_state | PI_STATE_HIT_DRAM;
			if (pi.opcode(PI_OPCODE_WIDTH - 1, 0) == PI_OPCODE_GET &&
			    (pi.opcode[7] & (!hb[NR_BITS_PERM_OFF + i]))) {
				/* if permission check failed, output status is failure */
				pi.pi_state = pi.pi_state | PI_STATE_NO_PERM;
				pi.slot_dram = 0;
				pi.output_status = PI_OUTPUT_FAILURE;
				pi.output = 0;
			} else {
				pi.slot_dram = i;
				pi.hb_dram = hb;
				pi.hb_dram_addr = cmd.address(NR_BITS_CHAIN_ADDR - 1, 0);
				pi.output_status = PI_OUTPUT_SUCCEED;
				pi.output = hb((i + 1) * NR_BITS_VAL - 1 + NR_BITS_VAL_OFF,
					       i * NR_BITS_VAL + NR_BITS_VAL_OFF);
			}
			pi_out->write(pi);
		} else {
			/*
			 * XXX
			 * If we are here, it means we even
			 * can not find the key on the DRAM bucket.
			 * Causes:
			 * 1) DRAM is empty
			 * 2) chained
			 * 3) BUG
			 *
			 * If DRAM is empty, all requests other than 0
			 * will come to here.
			 */
			if (pi.opcode(PI_OPCODE_WIDTH - 1, 0) == PI_OPCODE_SET &&
			    slot_dram_found == false) {
				/*
				 * while we read in a hash bucket and find the key,
				 * we find the empty slot at the same time so we
				 * don't need to do this in fill_S2.
				 * hb_dram stores the bucket hitted or the bucket that
				 * has a empty slot.
				 */
				int slot_d = 0;
				slot_d = find_empty_slot_dram(
					hb(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
					   NR_BITS_BITMAP_OFF));
				if (slot_d != -1) {
					slot_dram_found = true;
					pi.hb_dram = hb;
					pi.hb_dram_addr = cmd.address(NR_BITS_CHAIN_ADDR - 1, 0);
				}
				pi.slot_dram = slot_d;
			}

			if (hb[NR_BITS_CHAIN_FLAG_OFF] == 0) {
				/* there is no chaining bucket after this one */
				state = FILL_IDLE;
				pi.pi_state = pi.pi_state | PI_STATE_MISS_DRAM;
				pi.output_status = PI_OUTPUT_FAILURE;
				if (slot_dram_found == false) {
					pi.hb_dram = hb;
					pi.hb_dram_addr = cmd.address(NR_BITS_CHAIN_ADDR - 1, 0);
				}
				pi.output = 0;
				pi_out->write(pi);
			} else {
				/* there is a chaining bucket */
				cmd.address = hb(NR_BITS_CHAIN_ADDR - 1 +
							 NR_BITS_CHAIN_ADDR_OFF,
						 NR_BITS_CHAIN_ADDR_OFF);
				cmd.length = 1;
				state = FILL_SEND_CMD;
			}
		}
		break;
	}
}

void demux(stream<struct pipeline_info> *pi_in,
	   stream<struct mapping_reply> *rd_reply,
	   stream<struct mapping_reply> *wr_reply,
	   stream<struct table_request>	*addr_pop_req)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port=return

	if (!pi_in->empty()) {
		struct mapping_reply reply = { 0 };
		struct pipeline_info pi = { 0 };

		pi = pi_in->read();

		struct table_request req = { POP, 0 };
		addr_pop_req->write(req);

		reply.address = pi.output;
		reply.status = pi.output_status;
		reply.__internal_status = pi.pi_state;
		if (pi.channel == PI_CHANNEL_READ)
			rd_reply->write(reply);
		else if (pi.channel == MAPPING_REQUEST_WRITE)
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
 * O @alloc: allocation request for new hash bucket
 * I @alloc_ret: allocation response for new hash bucket
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
	       stream<ap_uint<MEM_BUS_WIDTH> >	*BRAM_wr_data,

	       stream<struct buddy_alloc_if>		*alloc,
	       stream<struct buddy_alloc_ret_if>	*alloc_ret)
{
#pragma HLS INLINE
#pragma HLS INTERFACE ap_ctrl_none port=return

	static stream<struct pipeline_info> PI_pipeline_info("PI_pipeline_info");
	static stream<struct pipeline_info> PI_hash_to_compare("PI_hash_to_compare");
	static stream<struct pipeline_info> PI_compare_to_fillS1("PI_compare_to_fillS1");
	static stream<struct pipeline_info> PI_fillS1_to_fillS2("PI_fillS1_to_fillS2");
	static stream<struct pipeline_info> PI_fillS2_to_out("PI_fill_to_out");

#pragma HLS STREAM variable=PI_pipeline_info		depth=128
#pragma HLS STREAM variable=PI_hash_to_compare		depth=128
#pragma HLS STREAM variable=PI_compare_to_fillS1	depth=128
#pragma HLS STREAM variable=PI_fillS1_to_fillS2		depth=128
#pragma HLS STREAM variable=PI_fillS2_to_out		depth=128

#if 0
#pragma HLS DATA_PACK variable=PI_pipeline_info
#pragma HLS DATA_PACK variable=PI_hash_to_compare
#pragma HLS DATA_PACK variable=PI_compare_to_fillS1
#pragma HLS DATA_PACK variable=PI_fillS1_to_fillS2
#pragma HLS DATA_PACK variable=PI_fillS2_to_out
#endif

	static stream<struct table_request>	fifo_addr_resv_req("addr_table_req");
	static stream<ap_uint<2> >		fifo_addr_resv_res("addr_table_res");
	static stream<struct table_request>	fifo_addr_pop_req("addr_pop__req");
#pragma HLS STREAM variable=fifo_addr_resv_req	depth=32
#pragma HLS STREAM variable=fifo_addr_resv_res	depth=32
#pragma HLS STREAM variable=fifo_addr_pop_req	depth=32

#pragma HLS DATA_PACK variable=fifo_addr_resv_req
#pragma HLS DATA_PACK variable=fifo_addr_pop_req

	remux(rd_request, wr_request, &PI_pipeline_info);

	compute_hash(&PI_pipeline_info, &PI_hash_to_compare);

	compare_bram_ht(&PI_hash_to_compare, &PI_compare_to_fillS1,
			BRAM_rd_cmd, BRAM_rd_data,
			&fifo_addr_resv_req, &fifo_addr_resv_res);

	fill_S1(&PI_compare_to_fillS1, &PI_fillS1_to_fillS2, DRAM_rd_cmd,
		DRAM_rd_data);

	fill_S2(&PI_fillS1_to_fillS2, &PI_fillS2_to_out,
		DRAM_wr_cmd, DRAM_wr_data,
		BRAM_wr_cmd, BRAM_wr_data,
		alloc, alloc_ret);

	demux(&PI_fillS2_to_out, rd_reply, wr_reply, &fifo_addr_pop_req);

	address_reservation_table(&fifo_addr_resv_req, &fifo_addr_resv_res, &fifo_addr_pop_req);
}
