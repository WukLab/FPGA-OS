/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/kernel.h>
#include "top.hpp"
#include "dm.hpp"

void buffer_req_read(stream<struct mapping_request> *in,
		     stream<struct mapping_request> *out)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off

	struct mapping_request req;
	if (!in->empty()) {
		req = in->read();
		out->write(req);
		/*
		 * Don't change it's opcode at this point.
		 */
	}
}

void buffer_req_write(stream<struct mapping_request> *in,
		      stream<struct mapping_request> *out)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off

	struct mapping_request req;
	if (!in->empty()) {
		req = in->read();
		req.opcode = MAPPING_REQUEST_WRITE;
		out->write(req);
	}
}

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
		hls::stream<struct buddy_alloc_ret_if>	*alloc_ret)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS DATAFLOW

#pragma HLS INTERFACE axis both port=in_read
#pragma HLS INTERFACE axis both port=in_write
#pragma HLS INTERFACE axis both port=out_read
#pragma HLS INTERFACE axis both port=out_write

#pragma HLS INTERFACE axis both port=DRAM_rd_cmd
#pragma HLS INTERFACE axis both port=DRAM_wr_cmd
#pragma HLS INTERFACE axis both port=DRAM_rd_data
#pragma HLS INTERFACE axis both port=DRAM_wr_data
#pragma HLS INTERFACE axis both port=DRAM_rd_status
#pragma HLS INTERFACE axis both port=DRAM_wr_status

#pragma HLS INTERFACE axis both port=BRAM_rd_cmd
#pragma HLS INTERFACE axis both port=BRAM_wr_cmd
#pragma HLS INTERFACE axis both port=BRAM_rd_data
#pragma HLS INTERFACE axis both port=BRAM_wr_data

#pragma HLS INTERFACE axis both port=alloc
#pragma HLS INTERFACE axis both port=alloc_ret

#pragma HLS DATA_PACK variable=in_read
#pragma HLS DATA_PACK variable=in_write
#pragma HLS DATA_PACK variable=out_read
#pragma HLS DATA_PACK variable=out_write
#pragma HLS DATA_PACK variable=DRAM_rd_cmd
#pragma HLS DATA_PACK variable=DRAM_wr_cmd
#pragma HLS DATA_PACK variable=BRAM_rd_cmd
#pragma HLS DATA_PACK variable=BRAM_wr_cmd
#pragma HLS DATA_PACK variable=alloc
#pragma HLS DATA_PACK variable=alloc_ret

	static stream<struct mapping_request>	fifo_read_req;
	static stream<struct mapping_request>	fifo_write_req;
#pragma HLS STREAM variable=fifo_read_req	depth=128
#pragma HLS STREAM variable=fifo_write_req	depth=128

#pragma HLS DATA_PACK variable=fifo_read_req
#pragma HLS DATA_PACK variable=fifo_write_req

	static stream<struct mem_cmd> fifo_DRAM_rd_cmd("fifo_DRAM_rd_cmd");
	static stream<struct mem_cmd> fifo_DRAM_wr_cmd("fifo_DRAM_wr_cmd");
	static stream<struct mem_cmd> fifo_BRAM_rd_cmd("fifo_BRAM_rd_cmd");
	static stream<struct mem_cmd> fifo_BRAM_wr_cmd("fifo_BRAM_wr_cmd");
#pragma HLS STREAM variable=fifo_DRAM_rd_cmd	depth=128
#pragma HLS STREAM variable=fifo_DRAM_wr_cmd	depth=128
#pragma HLS STREAM variable=fifo_BRAM_rd_cmd	depth=16
#pragma HLS STREAM variable=fifo_BRAM_wr_cmd	depth=16

#pragma HLS DATA_PACK variable=fifo_DRAM_rd_cmd
#pragma HLS DATA_PACK variable=fifo_DRAM_wr_cmd
#pragma HLS DATA_PACK variable=fifo_BRAM_rd_cmd
#pragma HLS DATA_PACK variable=fifo_BRAM_wr_cmd

	static stream<ap_uint<MEM_BUS_WIDTH> > fifo_DRAM_rd_data("fifo_DRAM_rd_data");
	static stream<ap_uint<MEM_BUS_WIDTH> > fifo_DRAM_wr_data("fifo_DRAM_wr_data");
	static stream<ap_uint<MEM_BUS_WIDTH> > fifo_BRAM_rd_data("fifo_BRAM_rd_data");
	static stream<ap_uint<MEM_BUS_WIDTH> > fifo_BRAM_wr_data("fifo_BRAM_wr_data");
#pragma HLS STREAM variable=fifo_DRAM_rd_data	depth=128
#pragma HLS STREAM variable=fifo_DRAM_wr_data	depth=128
#pragma HLS STREAM variable=fifo_BRAM_rd_data	depth=16
#pragma HLS STREAM variable=fifo_BRAM_wr_data	depth=16

	/*
	 * Front-end buffers were here to consume incoming
	 * data at every single cycle. Read and write requests
	 * share the same FIFO queue.
	 */
	buffer_req_read(in_read, &fifo_read_req);
	buffer_req_write(in_write, &fifo_write_req);

	/*
	 * Data path serves the AXI wrapper
	 */
	data_path(&fifo_read_req, &fifo_write_req,
		  out_read, out_write,
		  &fifo_DRAM_rd_cmd,  &fifo_DRAM_wr_cmd,
		  &fifo_DRAM_rd_data, &fifo_DRAM_wr_data,
		  &fifo_BRAM_rd_cmd,  &fifo_BRAM_wr_cmd,
		  &fifo_BRAM_rd_data, &fifo_BRAM_wr_data,
		  alloc, alloc_ret);

	/*
	 * Memory access part.
	 * We don't use AXI directly, instead, we talk with datamover.
	 */

	BRAM_rd_pipe(&fifo_BRAM_rd_cmd,
			&fifo_BRAM_rd_data,
			BRAM_rd_cmd,
			BRAM_rd_data);

	BRAM_wr_pipe(&fifo_BRAM_wr_cmd,
			 &fifo_BRAM_wr_data,
			 BRAM_wr_cmd,
			 BRAM_wr_data);

	DRAM_rd_pipe(&fifo_DRAM_rd_cmd,
			&fifo_DRAM_rd_data,
			DRAM_rd_cmd,
			DRAM_rd_data,
			DRAM_rd_status);

	DRAM_wr_pipe(&fifo_DRAM_wr_cmd,
			 &fifo_DRAM_wr_data,
			 DRAM_wr_cmd,
			 DRAM_wr_data,
			 DRAM_wr_status);
}
