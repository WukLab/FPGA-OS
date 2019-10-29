/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _MM_HLS_MAPPING_TOP_H_
#define _MM_HLS_MAPPING_TOP_H_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <fpga/axis_mapping.h>
#include <fpga/axis_buddy.h>

#include "hash.hpp"

using namespace hls;

#define MEM_BUS_WIDTH		512
#define NR_BYTES_MEM_BUS	(MEM_BUS_WIDTH/8)
#define MEM_BUS_TKEEP		NR_BYTES_MEM_BUS

/*
 * XXX
 * Probably need an array of return address..
 * Given the fact that AXI can be burst, one
 * AXI transaction may span multiple pages.
 */

#define PI_STATE_HIT_BRAM	(0x0001)
#define PI_STATE_HIT_DRAM	(0x0010)
#define PI_STATE_MISS_BRAM	(0x0100)
#define PI_STATE_MISS_DRAM	(0x1000)

#define PI_OPCODE_GET		1
#define PI_OPCODE_SET		2
#define PI_OPCODE_UNKNOWN	3

#define PI_CHANNEL_READ		0
#define PI_CHANNEL_WRITE	1

#define PI_OUTPUT_SUCCEED	0
#define PI_OUTPUT_FAILURE	1

struct pipeline_info {
	/* From input */
	ap_uint<MAPPING_VIRTUAL_WIDTH>		input;
	ap_uint<MAPPING_VIRTUAL_WIDTH>		length;
	ap_uint<8>				opcode;
	ap_uint<1>				channel;

	/*
	 * @hash: the computed hash value, used to index array.
	 * @addr: address of bucket in the hash chain
	 * @slot: matched slot number in the BRAM hash bucket
	 * @slot: matched slot number in the DRAM hash bucket
	 */
	ap_uint<NR_BITS_HASH>			hash;
	ap_uint<NR_BITS_CHAIN_ADDR> 		hb_dram_addr;
	ap_uint<NR_BITS_BUCKET>			hb_bram;
	ap_uint<NR_BITS_BUCKET>			hb_dram;
	int					slot;
	int					slot_dram;
	unsigned int				pi_state;

	/* For output */
	ap_uint<MAPPING_PHYSICAL_WIDTH>		output;
	ap_uint<1>				output_status;
};

void paging_top(hls::stream<struct mapping_request>	*in_read,
	        hls::stream<struct mapping_request>	*in_write,
	        hls::stream<struct mapping_reply>	*out_read,
	        hls::stream<struct mapping_reply>	*out_write,

		hls::stream<struct dm_cmd>		*DRAM_rd_cmd,
		hls::stream<struct dm_cmd>		*DRAM_wr_cmd,
		hls::stream<struct axis_mem>		*DRAM_rd_data,
		hls::stream<struct axis_mem>		*DRAM_wr_data,
		hls::stream<ap_uint<8> >		*DRAM_rd_status,
		hls::stream<ap_uint<8> >		*DRAM_wr_status,

		hls::stream<struct dm_cmd>		*BRAM_rd_cmd,
		hls::stream<struct dm_cmd>		*BRAM_wr_cmd,
		hls::stream<struct axis_mem>		*BRAM_rd_data,
		hls::stream<struct axis_mem>		*BRAM_wr_data,
		
		hls::stream<struct buddy_alloc_if>	*alloc,
		hls::stream<struct buddy_alloc_ret_if>	*alloc_ret);

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
	       stream<struct buddy_alloc_ret_if>	*alloc_ret);

void compute_hash(stream<struct pipeline_info> *in,
		  stream<struct pipeline_info> *out);

void DRAM_rd_pipe(stream<struct mem_cmd> *mem_read_cmd,
		  stream<ap_uint<MEM_BUS_WIDTH> > *mem_read_data,
		  stream<struct dm_cmd> *dm_read_cmd,
		  stream<struct axis_mem> *dm_read_data,
		  stream<ap_uint<8> > *dm_read_status);
void DRAM_wr_pipe(stream<struct mem_cmd> *mem_write_cmd,
		   stream<ap_uint<MEM_BUS_WIDTH> > *mem_write_data,
		   stream<struct dm_cmd> *dm_write_cmd,
		   stream<struct axis_mem> *dm_write_data,
		   stream<ap_uint<8> > *dm_write_status);
void BRAM_rd_pipe(stream<struct mem_cmd> *mem_read_cmd,
		  stream<ap_uint<MEM_BUS_WIDTH> > *mem_read_data,
		  stream<struct dm_cmd> *dm_read_cmd,
		  stream<struct axis_mem> *dm_read_data);
void BRAM_wr_pipe(stream<struct mem_cmd> *mem_write_cmd,
		   stream<ap_uint<MEM_BUS_WIDTH> > *mem_write_data,
		   stream<struct dm_cmd> *dm_write_cmd,
		   stream<struct axis_mem> *dm_write_data);
#endif /* _MM_HLS_MAPPING_TOP_H_ */
