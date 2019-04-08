/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _MM_HLS_PAGING_TOP_H_
#define _MM_HLS_PAGING_TOP_H_

#include <ap_axi_sdata.h>
#include <ap_int.h>

#include "hash.hpp"

using namespace hls;

#define PAGING_VIRTUAL_WIDTH	32
#define PAGING_PHYSICAL_WIDTH	32

#define MEM_BUS_WIDTH	512
#define MEM_BUS_TKEEP	64

/*
 * XXX
 * Probably need an array of return address..
 * Given the fact that AXI can be burst, one
 * AXI transaction may span multiple pages.
 */

#define MAPPING_REQUEST_READ		(0)
#define MAPPING_REQUEST_WRITE		(1)

struct paging_request {
	ap_uint<PAGING_VIRTUAL_WIDTH>	address;
	ap_uint<PAGING_VIRTUAL_WIDTH>	length;	
	ap_uint<1>			opcode;
};

struct paging_reply {
	ap_uint<PAGING_PHYSICAL_WIDTH>	address;
	ap_uint<1>			status;
};

#define PI_STATE_HIT	1
#define PI_STATE_MISS	2

struct pipeline_info {
	/* From input */
	ap_uint<PAGING_VIRTUAL_WIDTH>		input;
	ap_uint<PAGING_VIRTUAL_WIDTH>		length;
	ap_uint<1>				opcode;

	/* Intermidiate info during processing */
	ap_uint<NR_BITS_HASH>			hash;
	ap_uint<8>				pi_state;

	/* For output */
	ap_uint<PAGING_PHYSICAL_WIDTH>		output;
	ap_uint<1>				output_status;
};

void paging_top(hls::stream<struct paging_request>	*in_read,
	        hls::stream<struct paging_request>	*in_write,
	        hls::stream<struct paging_reply>	*out_read,
	        hls::stream<struct paging_reply>	*out_write,

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
		hls::stream<ap_uint<8> >		*BRAM_rd_status,
		hls::stream<ap_uint<8> >		*BRAM_wr_tatus);

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
	       stream<ap_uint<MEM_BUS_WIDTH> >	*BRAM_wr_data);

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
		  stream<struct axis_mem> *dm_read_data,
		  stream<ap_uint<8> > *dm_read_status);
void BRAM_wr_pipe(stream<struct mem_cmd> *mem_write_cmd,
		   stream<ap_uint<MEM_BUS_WIDTH> > *mem_write_data,
		   stream<struct dm_cmd> *dm_write_cmd,
		   stream<struct axis_mem> *dm_write_data,
		   stream<ap_uint<8> > *dm_write_status);
#endif /* _MM_HLS_PAGING_TOP_H_ */
